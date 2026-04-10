defmodule Khafra.SearchTable.TableObserver do
  @moduledoc """
  A per-node GenServer that creates a distributed table definition
  for each search table on startup.
  """
  use GenServer

  alias Khafra.SearchTable.{Operations, TableServer, TableSupervisor}
  alias Khafra.Struct.TableObserverState

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    send(self(), :create_distributed_tables)

    {:ok, %TableObserverState{}}
  end

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

    # Ensure each table has a distributed version
    Enum.each(schemas, fn schema ->
      Operations.create(struct(schema), :distributed, [])
    end)

    tables =
      schemas
      |> Map.new(fn schema ->
        {pid, _meta} = TableServer.lookup(schema)
        {schema, pid}
      end)

    {:noreply, %{state | tables: tables, schemas: schemas}}
  end
end
