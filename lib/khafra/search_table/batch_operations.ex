defmodule Khafra.SearchTable.BatchOperations do
  @moduledoc """
  Batch wrapper for table operations
  """
  alias Khafra.Queue.ManageTableProducer
  alias Khafra.SearchTable.BatchSupervisor

  @exchange "table_manager_exchange"
  @exchange_key "manage_tables_key"

  @doc """
  Run a batch of the provided operation using provided strategy.

  ## Strategies

    * Stream: immediately fully process the batch by streaming query
    * Queue: stream results and queue updates via RabbitMQ
    * Rate Limited Producer: Stagger load by querying x results and waiting between jobs
  """
  def batch_update(query, op, strategy \\ :stream)

  def batch_update(query, op, :stream) do
    repo = Application.get_env(:khafra_search, :repo)

    repo.transaction(fn ->
      query
      |> repo.stream()
      |> Enum.each(op)
    end)
  end

  def batch_update(query, op, :queue) do
    repo = Application.get_env(:khafra_search, :repo)

    repo.transaction(fn ->
      query
      |> repo.stream()
      |> Enum.each(fn record ->
           ManageTableProducer.publish(
             @exchange,
             @exchange_key,
             :erlang.term_to_binary({:record_op, record, op})
           )
         end)
    end)
  end

  def batch_update(query, op, {:rate_limited_producer, limit, minutes_between_jobs}) do
    BatchSupervisor.start_batch(query, op, limit, minutes_between_jobs)
  end
end
