defmodule Khafra.Application do
  @moduledoc false

  use Application

  def start_link() do
    Supervisor.start_link(__MODULE__, [], [])
  end

  def start(_type, _args) do
    :syn.add_node_to_scopes([:search_tables])

    children = [
      Khafra.Scheduler,
      Lapin.Supervisor,
      Khafra.SearchTable.BatchSupervisor,
      Khafra.SearchTable.TableSupervisor,
      Khafra.SearchTable.TableObserver
      | optional_deps(Application.get_env(:khafra_search, :repo))
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Khafra.Supervisor)
  end

  defp optional_deps(nil), do: []
  defp optional_deps(repo), do: [repo]
end
