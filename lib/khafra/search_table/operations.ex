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

  @doc """
  Drop a table if it exists
  """
  def drop_table(schema) when is_atom(schema) do
    schema
    |> Serialize.table_name()
    |> SearchTables.drop_table(if_exists: true)
  end

  @doc """
  Drop a tables distributed index
  """
  def drop_distributed_index(schema) when is_atom(schema) do
    schema
    |> Serialize.table_name()
    |> into_distributed_name()
    |> SearchTables.drop_table(if_exists: true)
  end

  @doc """
  Create a table from a SearchBehaviourSQL module.
  """
  def create_from_sql_behaviour(module, :rt, opts) do
    table_name = Atom.to_string(module.table_name())

    fields =
      module.index_fields()
      |> Enum.map(fn {name, type} -> {name, behaviour_to_manticore_type(type)} end)

    SearchTables.create_table_if_not_exists(table_name, fields, opts)
  end

  def create_from_sql_behaviour(module, :distributed, opts) do
    table_name = Atom.to_string(module.table_name())

    agents =
      opts
      |> Keyword.get(:agents, configured_agents())
      |> Enum.map(fn agent -> {:agent, "#{agent}:#{table_name}"} end)

    table_name
    |> into_distributed_name()
    |> SearchTables.create_distributed_table(agents, opts)
  end

  # PRIVATE FUNCTIONS
  ###################
  defp configured_agents() do
    :khafra_search
    |> Application.get_env(:distribution)
    |> Keyword.get(:agents)
  end

  defp behaviour_to_manticore_type(:integer), do: :bigint
  defp behaviour_to_manticore_type(:bigint),  do: :bigint
  defp behaviour_to_manticore_type(:float),   do: :float
  defp behaviour_to_manticore_type(:string),  do: :text
  defp behaviour_to_manticore_type(:text),    do: :text
  defp behaviour_to_manticore_type(:bool),    do: :bool
  defp behaviour_to_manticore_type(:boolean), do: :bool
  defp behaviour_to_manticore_type(:json),    do: :json
  defp behaviour_to_manticore_type(:timestamp), do: :bigint
  defp behaviour_to_manticore_type(:date),    do: :uint
  defp behaviour_to_manticore_type(type),     do: type
end
