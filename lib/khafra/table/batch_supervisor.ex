defmodule Khafra.Table.BatchSupervisor do
  @moduledoc """
  Dynamic supervisor for rate-limited batch operations
  """
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start a rate-limited batch operation under this supervisor
  """
  def start_batch(query, op, limit, minutes_between_jobs) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Khafra.Table.BatchServer, {query, op, limit, minutes_between_jobs}}
    )
  end
end