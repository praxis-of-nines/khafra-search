defmodule Khafra.SearchTable.Operations do
  @moduledoc """
  Search Table methods
  """
  alias Giza.SearchTables
  alias Khafra.Queue.ManageTableProducer
  alias Khafra.Serialize

  @exchange "table_manager_exchange"
  @exchange_key "manage_tables_key"

  # Defaults applied to every RT table creation regardless of caller. Centralised
  # here so that direct callers (e.g. `TableServer` at startup) get the same
  # behaviour as `Khafra.create_table/2` going through `SearchTable.create/2`.
  @default_rt_opts [fuzzy_match: true]

  @doc """
  Insert or update a table row
  """
  def replace(table_name, row, strategy \\ :immediate)

  def replace(table_name, row, nil) do
    replace(table_name, row, :immediate)
  end

  def replace(table_name, row, :immediate) do
    table_name
    |> SearchTables.replace(
         Serialize.keys(row),
         Serialize.values(row)
       )
  end

  def replace(table_name, row, :queue) do
    ManageTableProducer.publish(
      @exchange,
      @exchange_key,
      :erlang.term_to_binary({:record_op, fn -> replace(table_name, row, :immediate) end})
    )
  end

  @doc """
  Create table.

  ## Real Time (rt)

  Standard real time table that accepts inserts/updates and is always searchable

  ## Distributed

  A reference to a group of RT tables (not in itself a table)
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
    |> Khafra.into_distributed_name()
    |> SearchTables.create_distributed_table(agents, opts)
  end

  def create(schema, :rt, opts) do
    schema
    |> Serialize.table_name()
    |> SearchTables.create_table_if_not_exists(
         Serialize.search_table_schema(struct(schema)),
         Keyword.merge(@default_rt_opts, opts)
       )
  end

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
    |> Khafra.into_distributed_name()
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

    SearchTables.create_table_if_not_exists(
      table_name,
      fields,
      Keyword.merge(@default_rt_opts, opts)
    )
  end

  def create_from_sql_behaviour(module, :distributed, opts) do
    table_name = Atom.to_string(module.table_name())

    agents =
      opts
      |> Keyword.get(:agents, configured_agents())
      |> Enum.map(fn agent -> {:agent, "#{agent}:#{table_name}"} end)

    table_name
    |> Khafra.into_distributed_name()
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
