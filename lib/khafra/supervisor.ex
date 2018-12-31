defmodule Khafra.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, [])
  end

  def init(:ok) do
    _ = Application.ensure_all_started(:timex)
    
    children = [
      worker(Khafra.Scheduler, []),
      supervisor(SimpleStatEx.StatSupervisor, [])
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end