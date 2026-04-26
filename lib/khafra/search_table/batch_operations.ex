defmodule Khafra.SearchTable.BatchOperations do
  @moduledoc """
  Batch wrapper for table operations
  """
  use SQL, pool: :default
  
  alias Khafra.Queue.ManageTableProducer
  alias Khafra.SearchTable.BatchSupervisor
  alias Khafra.Serialize

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

  def batch_update(%SQL{columns: columns, pool: pool} = query, op, :stream) do
    table = Serialize.table_name(query)
    columns = ensure_typed(columns, table, pool)

    SQL.transaction do
      query
      |> SQL.stream()
      |> Enum.each(fn row ->
           op.(
             table,
             decode_row(row, columns),
             strategy: :immediate
           )
         end)
    end
  end

  def batch_update(query, op, :stream) do
    repo = Application.get_env(:khafra_search, :repo)

    repo.transaction(fn ->
      query
      |> repo.stream()
      |> Enum.each(fn row ->
           op.(
            query |> Serialize.table_name(),
            row,
            strategy: :immediate
          )
         end)
    end)
  end

  def batch_update(%SQL{columns: columns, pool: pool} = query, op, :queue) do
    columns = ensure_typed(columns, Serialize.table_name(query), pool)

    SQL.transaction do
      query
      |> SQL.stream()
      |> Enum.each(fn record ->
           ManageTableProducer.publish(
             @exchange,
             @exchange_key,
             :erlang.term_to_binary({:record_op, decode_row(record, columns), op})
           )
         end)
    end
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

  # When a `~SQL` sigil is expanded outside a `use SQL` module (e.g. at the iex
  # prompt), `SQL.build/4` resolves `columns` from an empty schema, so the
  # struct's columns metadata loses its postgres type info — each entry comes
  # back as `{nil, :col_name}`. The postgres adapter's `decode/2` has no clause
  # for a `nil` type and falls through to the catch-all that returns the raw
  # 4/8-byte binary, which Manticore then can't parse as an integer for the
  # `id` column and auto-assigns its own. We recover the missing types here
  # from the same `:persistent_term` cache `SQL.Application` populates, then
  # re-decode int columns so document ids match the source database.
  defp decode_row(row, columns) when is_list(row) and is_list(columns) do
    row
    |> Enum.zip(columns)
    |> Enum.map(fn {{key, value}, col} -> {key, decode_value(col, value)} end)
  end

  defp decode_row(row, _columns), do: row

  defp decode_value({type, _col}, value), do: decode_value(type, value)
  defp decode_value([type], value), do: decode_value(type, value)
  defp decode_value(:int2, <<val::signed-16-big>>), do: val
  defp decode_value(:int4, <<val::signed-32-big>>), do: val
  defp decode_value(:int8, <<val::signed-64-big>>), do: val
  defp decode_value(_type, value), do: value

  defp ensure_typed(columns, _table, _pool) when not is_list(columns), do: columns

  defp ensure_typed(columns, table, pool) do
    case Enum.any?(columns, &match?({nil, _}, &1)) do
      true -> hydrate_types(columns, table, pool)
      false -> columns
    end
  end

  defp hydrate_types(columns, nil, _pool), do: columns

  defp hydrate_types(columns, table, pool) do
    pg_columns = :persistent_term.get({pool, :columns}, [])
    table_str = to_string(table)

    Enum.map(columns, fn
      {nil, col_name} ->
        case Enum.find(pg_columns, fn pg ->
               pg.table_name == table_str and pg.column_name == to_string(col_name)
             end) do
          nil -> {nil, col_name}
          %{udt_name: udt} -> {String.to_atom(udt), col_name}
        end

      other ->
        other
    end)
  end
end
