defmodule Khafra.LiveDashboard.QueryMetricsPage do
  @moduledoc """
  A Phoenix LiveDashboard page displaying real-time charts for
  Giza SphinxQL query telemetry.

  Subscribes to `[:giza, :query, :stop]` and `[:giza, :query, :exception]`
  telemetry events and renders live-updating charts for query count,
  duration, and error count.

  ## Usage

  Add to your router's `live_dashboard` configuration:

      live_dashboard "/dashboard",
        additional_pages: [
          search_tables: Khafra.LiveDashboard.SearchTablesPage,
          query_metrics: Khafra.LiveDashboard.QueryMetricsPage
        ]
  """
  use Phoenix.LiveDashboard.PageBuilder

  @handler_id "khafra-query-metrics"

  @impl true
  def menu_link(_, _) do
    {:ok, "Query Metrics"}
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      attach_telemetry(self())
    end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.row>
      <:col>
        <.live_chart
          id="giza-query-count"
          title="Query Count"
          kind={:counter}
          label="queries"
          unit=""
          prune_threshold={1_000}
        />
      </:col>
      <:col>
        <.live_chart
          id="giza-query-duration"
          title="Query Duration"
          kind={:summary}
          label="duration"
          unit=" ms"
          prune_threshold={1_000}
        />
      </:col>
      <:col>
        <.live_chart
          id="giza-query-errors"
          title="Query Errors"
          kind={:counter}
          label="errors"
          unit=""
          prune_threshold={1_000}
        />
      </:col>
    </.row>
    <.row>
      <:col>
        <.live_chart
          id="giza-query-duration-by-source"
          title="Duration by Source"
          kind={:summary}
          label="duration"
          tags={[]}
          unit=" ms"
          prune_threshold={1_000}
          full_width={true}
        />
      </:col>
    </.row>
    """
  end

  @impl true
  def handle_info({:giza_telemetry, :stop, duration_ms, source}, socket) do
    label = source_label(source)

    send_data_to_chart("giza-query-count", [{label, now_x(), 1}])
    send_data_to_chart("giza-query-duration", [{label, now_x(), duration_ms}])
    send_data_to_chart("giza-query-duration-by-source", [{label, now_x(), duration_ms}])

    {:noreply, socket}
  end

  def handle_info({:giza_telemetry, :exception, duration_ms, source}, socket) do
    label = source_label(source)

    send_data_to_chart("giza-query-count", [{label, now_x(), 1}])
    send_data_to_chart("giza-query-errors", [{label, now_x(), 1}])
    send_data_to_chart("giza-query-duration", [{label, now_x(), duration_ms}])

    {:noreply, socket}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp attach_telemetry(pid) do
    events = [[:giza, :query, :stop], [:giza, :query, :exception]]

    :telemetry.attach_many(
      "#{@handler_id}-#{inspect(pid)}",
      events,
      &__MODULE__.handle_telemetry_event/4,
      pid
    )
  end

  @doc false
  def handle_telemetry_event([:giza, :query, :stop], %{duration: duration}, metadata, pid) do
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    send(pid, {:giza_telemetry, :stop, duration_ms, metadata[:source]})
  end

  def handle_telemetry_event([:giza, :query, :exception], %{duration: duration}, metadata, pid) do
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    send(pid, {:giza_telemetry, :exception, duration_ms, metadata[:source]})
  end

  defp now_x, do: DateTime.utc_now() |> DateTime.to_unix(:millisecond)

  defp source_label(nil), do: "unknown"
  defp source_label(source) when is_binary(source), do: source
  defp source_label(source), do: to_string(source)
end
