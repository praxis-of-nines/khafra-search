defmodule Khafra.Application do
  @moduledoc false

  use Application

  @env Application.compile_env(:khafra_search, :env)

  def start_link() do
    Supervisor.start_link(__MODULE__, [], [])
  end

  def start(_type, _args) do
    children = [
      Khafra.Scheduler,
      Lapin.Supervisor,
      Khafra.Table.BatchSupervisor
      | env_deps(@env)
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Khafra.Supervisor)
  end

  defp env_deps(:dev) do
    [
      Khafra.Sample.Repo
    ]
  end

  defp env_deps(_), do: []
end
