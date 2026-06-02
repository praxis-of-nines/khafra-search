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
    sql_modules = TableSupervisor.sql_modules()

    # Ensure each Ecto table has a distributed version
    Enum.each(schemas, fn schema ->
      Operations.create(struct(schema), :distributed, [])
    end)

    # Ensure each SQL table has a distributed version
    Enum.each(sql_modules, fn module ->
      Operations.create_from_sql_behaviour(module, :distributed, [])
    end)

    tables =
      schemas
      |> Kernel.++(sql_modules)
      |> Enum.reduce(%{}, fn mod, acc ->
        case TableServer.lookup(mod) do
          {pid, _meta} -> Map.put(acc, mod, pid)
          :undefined -> acc
        end
      end)

    {:noreply, %{state | tables: tables, schemas: schemas, sql_modules: sql_modules}}
  end
end
