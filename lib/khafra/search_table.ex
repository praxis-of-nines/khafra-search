defmodule Khafra.SearchTable do
  @moduledoc """
  Search Table methods
  """
  alias Giza.SearchTables
  alias Khafra.SearchTable.{BatchOperations, Operations}
  alias Khafra.Queue.ManageTableProducer
  alias Khafra.Serialize

  @exchange "table_manager_exchange"
  @exchange_key "manage_tables_key"

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
  Create a table modifying by provided opts. By default creates a distributed
  table using configured agents.
  """
  def create(query, opts \\ [])

  def create(query, opts) do
    # merge opts with default create opts
    {table_type, opts} = default_create_opts()
                         |> Keyword.merge(opts)
                         |> Keyword.pop!(:type)

    Operations.create(schema, table_type, opts)
  end

  # PRIVATE FUNCTIONS
  ###################
  defp default_create_opts do
    [
      {type: :distributed}
    ]
  end
end
