defmodule Khafra.SearchTable.TableServer do
  @moduledoc """
  GenServer representing a single manticore real-time table.
  """
  use GenServer

  alias Giza.SearchTables
  alias Giza.Structs.SphinxqlResponse
  alias Khafra.Serialize
  alias Khafra.Struct.TableServerState

  @scope :search_tables
  @max_jitter_ms :timer.minutes(60)

  def start_link(schema) do
    GenServer.start_link(
      __MODULE__,
      schema,
      name: {:via, :syn, {@scope, {:table, schema}, %{schema: schema}}}
    )
  end

  @impl true
  def init(schema) do
    search_table = schema
                 |> struct()
                 |> Serialize.table_name()

    {:ok, update_table_status(%TableServerState{schema: schema, search_table: search_table})}
  end

  @doc "Look up the pid for a table server by schema module"
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

  defp no_reply(state), do: {:noreply, state}
end
