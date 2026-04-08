defmodule Khafra.SearchTable.TableObserver do
  @moduledoc """
  A globally unique GenServer (one per cluster) that creates a
  distributed table definition for each search table on startup.
  """
  use GenServer

  alias Khafra.SearchTable.{Operations, TableServer, TableSupervisor}
  alias Khafra.Struct.TableObserverState

  @scope :search_tables

  def start_link(opts) do
    case GenServer.start_link(__MODULE__, opts, name: {:via, :syn, {@scope, :table_observer}}) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, _pid}} -> :ignore
    end
  end

  @impl true
  def init(_opts) do
    send(self(), :create_distributed_tables)

    {:ok, %{tables: %TableObserverState{}}}
  end

  @doc "Look up the pid for a table server by schema module"
  def lookup, do: :syn.lookup(@scope, :table_observer)

  @impl true
  def handle_call(:peek, _, state), do: {:reply, state, state}

  @impl true
  def handle_cast(:maintain_all, %{tables: tables} = state) do
    Enum.each(tables, fn {_schema, pid} ->
      GenServer.cast(pid, :maintain)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info(:create_distributed_tables, state) do
    schemas = TableSupervisor.search_schemas()

    Enum.each(schemas, fn schema ->
      Operations.create(struct(schema), :distributed, [])
    end)

    tables =
      schemas
      |> Map.new(fn schema ->
        {pid, _meta} = TableServer.lookup(schema)
        {schema, pid}
      end)

    {:noreply, %{state | tables: tables}}
  end
end
