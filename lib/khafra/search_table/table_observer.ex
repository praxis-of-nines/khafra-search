defmodule Khafra.SearchTable.TableObserver do
  @moduledoc """
  A globally unique GenServer (one per cluster) that creates a
  distributed table definition for each search table on startup.
  """
  use GenServer

  alias Khafra.SearchTable.{Operations, TableSupervisor}

  @scope :search_tables

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_opts) do
    case :syn.register(@scope, :table_observer, self()) do
      :ok ->
        send(self(), :create_distributed_tables)
        {:ok, %{}}

      {:error, :taken} ->
        :ignore
    end
  end

  @impl true
  def handle_info(:create_distributed_tables, state) do
    TableSupervisor.search_schemas()
    |> Enum.each(fn schema ->
      Operations.create(struct(schema), :distributed, [])
    end)

    {:noreply, state}
  end
end
