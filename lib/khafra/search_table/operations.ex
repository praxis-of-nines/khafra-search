defmodule Khafra.SearchTable.Operations do
  @moduledoc """
  Search Table methods
  """
  alias Giza.SearchTables
  alias Khafra.Queue.ManageTableProducer
  alias Khafra.Serialize

  @exchange "table_manager_exchange"
  @exchange_key "manage_tables_key"

  @doc """
  Insert or update a table row
  """
  def replace(entity, strategy \\ :immediate)

  def replace(%{} = entity, nil) do
    replace(entity, :immediate)
  end

  def replace(%{} = entity, :immediate) do
    entity
    |> Serialize.table_name()
    |> SearchTables.replace(
         Serialize.keys(entity),
         Serialize.values(entity)
       )
  end

  def replace(%{} = entity, :queue) do
    ManageTableProducer.publish(
      @exchange,
      @exchange_key,
      :erlang.term_to_binary({:record_op, fn -> replace(entity, :immediate) end})
    )
  end

  @doc """
  Create table.

  ## Real Time (rt)



  ## Distributed


  """
  def create(schema, :distributed, opts) do
    table_name = Serialize.table_name(schema)

    agents = opts
             |> Keyword.get(
               :agents,
               configured_agents()
             )
             |> Enum.map(fn agent -> {:agent, "#{agent}:#{table_name}"} end)
             
    table_name
    |> into_distributed_name()
    |> SearchTables.create_distributed_table(agents, opts)
  end

  def create(schema, :rt, opts) do
    schema
    |> Serialize.table_name()
    |> SearchTables.create_table_if_not_exists(
         Serialize.search_table_schema(struct(schema)),
         opts
       )
  end

  @doc """
  Derive the regular table name into the distributed name
  khafra standardizes
  """
  def into_distributed_name(name), do: "#{name}_dist"

  # PRIVATE FUNCTIONS
  ###################
  defp configured_agents() do
    :khafra_search
    |> Application.get_env(:distribution)
    |> Keyword.get(:agents)
  end
end
