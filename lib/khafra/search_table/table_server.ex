defmodule Khafra.SearchTable.TableServer do
  @moduledoc """
  GenServer representing a single manticore real-time table.
  """
  use GenServer

  alias Giza.SearchTables
  alias Giza.Structs.SphinxqlResponse
  alias Khafra.SearchTable.Operations
  alias Khafra.Serialize
  alias Khafra.Struct.TableServerState

  @scope :search_tables
  @max_jitter_ms :timer.minutes(60)

  def start_link({:sql, module}) do
    GenServer.start_link(
      __MODULE__,
      {:sql, module},
      name: {:via, :syn, {@scope, {:table, module}, %{module: module}}}
    )
  end

  def start_link(schema) do
    GenServer.start_link(
      __MODULE__,
      schema,
      name: {:via, :syn, {@scope, {:table, schema}, %{schema: schema}}}
    )
  end

  @impl true
  def init({:sql, module}) do
    search_table = Atom.to_string(module.table_name())

    {
      :ok,
      %TableServerState{schema: module, search_table: search_table}
      |> ensure_sql_table(module)
      |> update_table_status()
    }
  end

  def init(schema) do
    search_table = schema
                 |> struct()
                 |> Serialize.table_name()

    {
      :ok,
      %TableServerState{schema: schema, search_table: search_table}
      |> ensure_table()
      |> update_table_status()
    }
  end

  @doc "Look up the pid for a table server by schema or SQL behaviour module"
  def lookup(schema), do: :syn.lookup(@scope, {:table, schema})

  @impl true
  def handle_call(:peek, _, state), do: {:reply, state, state}

  @impl true
  def handle_cast(:maintain, state) do
    Process.send_after(self(), :run_maintenance, :rand.uniform(@max_jitter_ms))

    {:noreply, state}
  end

  @impl true
  def handle_info(:run_maintenance, state) do
    state
    |> optimize_table()
    |> update_table_status()
    |> no_reply()
  end

  # PRIVATE FUNCTIONS
  ###################
  defp ensure_table(%TableServerState{schema: schema} = state) do
     _ = Operations.create(schema, :rt, [])

     state
  end

  defp ensure_sql_table(state, module) do
    _ = Operations.create_from_sql_behaviour(module, :rt, [])

    state
  end

  defp optimize_table(%TableServerState{search_table: search_table} = state) do
    _ = SearchTables.optimize_table(search_table)

    state
  end

  defp update_table_status(%TableServerState{search_table: search_table} = state) do
    search_table
    |> SearchTables.show_table_status()
    |> status_into_state(state)
  end

  defp status_into_state({_ok, %SphinxqlResponse{matches: statuses}}, state) do
    %{state | table_status: Enum.reduce(
                              statuses,
                              %{},
                              fn [k, v], acc -> Map.put(acc, String.to_atom(k), v) end
                            )
    }
  end

  defp status_into_state({:error, _reason}, state), do: state

  defp no_reply(state), do: {:noreply, state}
end
