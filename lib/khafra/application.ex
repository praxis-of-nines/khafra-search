defmodule Khafra.Application do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], [])
  end

  def init(_opts) do
    _ = Application.ensure_all_started(:timex)
    
    children = [
      Khafra.Scheduler
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end