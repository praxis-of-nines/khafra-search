defmodule Khafra do
  @moduledoc """
  Khafra: The distributed search deployment platform
  """
  alias Giza.SearchTables
  alias Khafra.{Log, Serialize}
  alias Khafra.Table.BatchOperations

  @strategy Application.compile_env(:khafra_search, :strategies)

  @doc """
  Insert, creating table if it does not exist yet
  """
  def insert(result), do: maybe_replace(result)

  @doc """
  Update an entries full fields
  """
  def update(result), do: maybe_replace(result)

  @doc """
  Works off a struct which represents a table name and fills all search
  rows. Note this can be an expensive operation on large tables; use 
  options to schedule work if necessary.
  """
  def refresh_table(schema, opts \\ [])

  def refresh_table(schema, opts) when is_atom(schema) do
    schema
    |> batch_operations(&update/1, Keyword.get(opts, :strategy, :stream))
    |> Log.batch_operation()
  end

  @doc """
  Dump the output of a command line result
  """
  def output_stream_command_result({result, _}) do
    Enum.each(String.split(result, "\n"), fn result_line ->
      IO.puts result_line
    end)
  end

  # PRIVATE FUNCTIONS
  ###################
  defp maybe_replace({:ok, entity}) do
    {:ok, maybe_replace(entity)}
  end

  defp maybe_replace(%_schema{} = entity) do
    entity
    |> implements_search_behaviour()
    |> maybe_replace(entity)
  end

  defp maybe_replace(result), do: result

  defp maybe_replace(true, entity) do
    # [update_strategy: :naive, update_all_strategy: :queue]
    _ = entity
        |> Serialize.table_name()
        |> SearchTables.replace(
             Serialize.keys(entity),
             Serialize.values(entity)
           )
        |> Log.replace()

    entity
  end

  defp maybe_replace(_, entity), do: entity

  defp implements_search_behaviour(%schema{}) do
    schema.module_info(:attributes)
    |> Keyword.get_values(:behaviour)
    |> List.flatten()
    |> Enum.member?(Khafra.SearchBehaviour)
  end

  defp implements_search_behaviour(_), do: false

  defp batch_operations(query, op, strategy) do
    BatchOperations.batch_update(query, op, strategy)
  end
end
