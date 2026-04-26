defmodule Khafra do
  @moduledoc """
  Khafra: The distributed search deployment platform
  """
  alias Giza.ManticoreQL
  alias Khafra.Log
  alias Khafra.{SearchTable, Observer, Serialize}

  @doc """
  Insert, creating table if it does not exist yet
  """
  def insert(result, opts \\ []), do: maybe_replace(result, opts)

  @doc """
  Update an entries full fields
  """
  def update(result, opts \\ []), do: maybe_replace(result, opts)


  @doc """
  Taking a query from an ORM or SQL struct build a giza query to a distributed
  table using the standardized khafra naming. Takes advantage of giza passthrough
  to ignore nil values. Note that depending on SearchBehaviour fields indexed,
  some queries would fail such as asking to constrain where on a field not existing
  in the search index.

  Supports
  
    * Ecto
    * https://github.com/elixir-dbvisor/sql
    * Manual table call
  """
  def match(table_or_query, opts \\ [])

  def match(%SQL{} = sql, _opts) do
    table = Serialize.table_name(sql)

    ManticoreQL.new()
    |> ManticoreQL.from("#{table}_dist")
    |> ManticoreQL.select(select_fields(sql))
    |> apply_match(match_phrase(sql))
    |> Giza.send()
  end

  def match(%schema{where: where}, _opts) do
    ManticoreQL.new()
    |> ManticoreQL.from("#{Serialize.table_name(schema)}_dist")
    |> ManticoreQL.match("*#{where}*")
    |> Giza.send()
  end

  @doc """
  Works off a struct which represents a table name and fills all search
  rows. Note this can be an expensive operation on large tables; use 
  options to schedule work if necessary.
  """
  def refresh_table(schema, opts \\ []) do
    schema
    |> SearchTable.batch_replace(opts)
    |> Log.batch_operation()
  end

  @doc """
  Create a table using configured strategy and options
  """
  def create_table(schema, opts \\ []) do
    schema
    |> SearchTable.create(opts)
    |> Log.create_table()
  end

  @doc """
  Trigger jigged maintenance on all registered table servers
  """
  def trigger_maintenance, do: Observer.trigger_maintenance()

  @doc "Get Observer state; list of search tables"
  def peek(:observer), do: SearchTable.peek(:observer)

  @doc "Get a search tables state from the schema it backs"
  def peek(:table, schema), do: SearchTable.peek(:table, schema)

  @doc """
  Remove all tables. Generally for testing. This drops for the
  current node only
  """
  def destroy_all do
    Observer.get_schemas()
    |> Enum.map(fn schema ->
      {
        SearchTable.drop_table(schema),
        SearchTable.drop_distributed_index(schema)
      }
    end)
  end

  @doc """
  Derive the regular table name into the distributed name
  khafra standardizes
  """
  def into_distributed_name(name), do: "#{name}_dist"

  # PRIVATE FUNCTIONS
  ###################
  defp apply_match(query, nil), do: query
  defp apply_match(query, phrase), do: ManticoreQL.match(query, phrase)

  defp select_fields(%SQL{string: string}) do
    case Regex.run(~r/\bselect\s+(.+?)\s+from\b/is, string) do
      [_, fields] ->
        fields
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))

      _ ->
        ["*"]
    end
  end

  # Translate a SQL `WHERE field = 'value' [AND field = 'value']...` clause into
  # Manticore's full-text MATCH syntax (`@field "value" ...`). Manticore disallows
  # attribute-style filters on stored fields, so equality predicates on
  # full-text fields must be expressed as MATCH expressions instead.
  defp match_phrase(%SQL{string: string}) do
    with [_, where] <-
           Regex.run(
             ~r/\bwhere\s+(.+?)(?:\s+(?:order\s+by|group\s+by|limit|offset)\b|$)/is,
             string
           ),
         phrase when phrase != "" <- where_to_match(where) do
      phrase
    else
      _ -> nil
    end
  end

  defp where_to_match(where) do
    ~r/(\w+)\s*=\s*'([^']*)'/
    |> Regex.scan(where)
    |> Enum.map_join(" ", fn [_, field, value] ->
      "@#{field} #{infix(value)}"
    end)
  end

  # Wrap each whitespace-separated token in `*...*` so Manticore performs an
  # infix match per word (mirrors the `%schema{}` clause's `"*#{where}*"`
  # behavior, but applied per-word so multi-word values still match as infixes).
  defp infix(value) do
    value
    |> String.split()
    |> Enum.map_join(" ", &"*#{&1}*")
  end

  defp maybe_replace({:ok, entity}, opts) do
    {:ok, maybe_replace(entity, opts)}
  end

  defp maybe_replace(%_schema{} = entity, opts) do
    entity
    |> implements_search_behaviour()
    |> maybe_replace(entity, opts)
  end

  defp maybe_replace(result, _opts), do: result

  defp maybe_replace(true, entity, opts) do
    _ = entity
        |> SearchTable.replace(opts)
        |> Log.replace()

    entity
  end

  defp maybe_replace(_, entity, _opts), do: entity

  defp implements_search_behaviour(%schema{}) do
    schema.module_info(:attributes)
    |> Keyword.get_values(:behaviour)
    |> List.flatten()
    |> Enum.member?(Khafra.SearchBehaviour)
  end

  defp implements_search_behaviour(_), do: false
end
