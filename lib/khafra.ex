defmodule Khafra do
  @moduledoc """
  Khafra: The distributed search deployment platform
  """
  alias Khafra.Log
  alias Khafra.{SearchTable, Observer}

  @doc """
  Insert, creating table if it does not exist yet
  """
  def insert(result, opts \\ []), do: maybe_replace(result, opts)

  @doc """
  Update an entries full fields
  """
  def update(result, opts \\ []), do: maybe_replace(result, opts)

  @doc """
  Works off a struct which represents a table name and fills all search
  rows. Note this can be an expensive operation on large tables; use 
  options to schedule work if necessary.
  """
  def refresh_table(schema, opts \\ []) when is_atom(schema) do
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

  # PRIVATE FUNCTIONS
  ###################
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
        |> SearchTable.replace(Keyword.get(opts, :strategy))
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
