defmodule Khafra.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    :syn.add_node_to_scopes([:search_tables])

    children = [
      Khafra.Scheduler,
      Lapin.Supervisor,
      Khafra.SearchTable.BatchSupervisor,
      Khafra.SearchTable.TableSupervisor,
      Khafra.SearchTable.TableObserver
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
