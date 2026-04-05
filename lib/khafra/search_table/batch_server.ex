defmodule Khafra.SearchTable.BatchServer do
  @moduledoc """
  GenServer for processing batch operations with rate limiting.

  Processes `limit` records at a time with a configurable delay between batches.
  Stops itself when all records have been processed.
  """
  use GenServer

  require Logger

  import Ecto.Query

  def start_link({_query, _op, _limit, _minutes_between_jobs} = args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init({query, op, limit, minutes_between_jobs}) do
    state = %{
      query: query,
      op: op,
      limit: limit,
      interval: :timer.minutes(minutes_between_jobs),
      offset: 0
    }

    send(self(), :process_batch)

    {:ok, state}
  end

  @impl true
  def handle_info(:process_batch, %{query: query, limit: limit, offset: offset} = state) do
    repo = Application.get_env(:khafra_search, :repo)

    records =
      query
      |> limit(^limit)
      |> offset(^offset)
      |> repo.all()

    Enum.each(records, state.op)

    Logger.debug(fn ->
      "BatchServer processed #{length(records)} records at offset #{state.offset}"
    end)

    maybe_next_batch(state, length(records))
  end

  # PRIVATE FUNCTIONS
  ###################
  defp maybe_next_batch(%{limit: limit}, remaining_records) when remaining_records < limit do
    {:stop, :normal, :state}
  end

  defp maybe_next_batch(%{interval: interval, offset: offset, limit: limit} = state, _) do
    Process.send_after(self(), :process_batch, interval)
    
    {:noreply, %{state | offset: offset + limit}}
  end
end