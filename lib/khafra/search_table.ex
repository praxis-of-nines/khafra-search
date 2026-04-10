defmodule Khafra.SearchTable do
  @moduledoc """
  Search Table methods
  """
  alias Khafra.SearchTable.{
                             BatchOperations,
                             Operations,
                             TableObserver,
                             TableServer
                           }

  @doc """
  Insert or update a table row
  """
  def replace(entity, opts \\ []) do
    Operations.replace(entity, Keyword.get(opts, :strategy))
  end

  @doc """
  Run a batch of replace operations using the provided strategy
  """
  def batch_replace(query, opts \\ []) do
    BatchOperations.batch_update(
      query,
      &replace/1,
      Keyword.get(opts, :strategy, :stream)
    )
  end

  @doc """
  Create a table modifying by provided opts.
  """
  def create(schema, opts \\ [])

  def create(schema, opts) do
    # merge opts with default create opts
    {table_type, opts} = default_create_opts()
                         |> Keyword.merge(opts)
                         |> Keyword.pop!(:type)

    
    Operations.create(schema, table_type, opts)
  end

  @doc "Get Observer state; list of search tables"
  def peek(:observer), do: GenServer.call(TableObserver, :peek)

  @doc "Get a search tables state from the schema it backs"
  def peek(:table, schema), do: TableServer.lookup(schema)
                                |> pid()
                                |> GenServer.call(:peek)

  @doc "Delete a table"
  def drop_table(schema), do: Operations.drop_table(schema)

  @doc "Delete a distributed index"
  def drop_distributed_index(schema), do: Operations.drop_distributed_index(schema)

  # PRIVATE FUNCTIONS
  ###################
  defp pid({pid, _meta}), do: pid

  defp default_create_opts do
    [
      {:type, :rt},
      {:fuzzy_match, true}
    ]
  end
end
