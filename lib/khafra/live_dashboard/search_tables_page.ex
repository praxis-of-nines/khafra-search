defmodule Khafra.LiveDashboard.SearchTablesPage do
  @moduledoc """
  A Phoenix LiveDashboard page displaying the status of all
  Manticore search tables managed by Khafra.

  ## Usage

  Add to your router's `live_dashboard` configuration:

      live_dashboard "/dashboard",
        additional_pages: [
          search_tables: Khafra.LiveDashboard.SearchTablesPage
        ]
  """
  use Phoenix.LiveDashboard.PageBuilder

  @impl true
  def menu_link(_, _) do
    {:ok, "Search Tables"}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_table
      id="khafra-search-tables"
      dom_id="khafra-search-tables"
      page={@page}
      title="Search Tables"
      row_fetcher={&fetch_tables/2}
      rows_name="tables"
    >
      <:col field={:search_table} header="Table" sortable={:asc} />
      <:col field={:schema} header="Schema" />
      <:col field={:indexed_documents} header="Documents" text_align="right" sortable={:desc} />
      <:col field={:ram_bytes} header="RAM Bytes" text_align="right" sortable={:desc} />
      <:col field={:disk_bytes} header="Disk Bytes" text_align="right" sortable={:desc} />
    </.live_table>
    """
  end

  defp fetch_tables(params, node) do
    %{search: search, sort_by: sort_by, sort_dir: sort_dir, limit: limit} = params

    rows =
      case :rpc.call(node, __MODULE__, :table_statuses, []) do
        {:badrpc, _} -> []
        result -> result
      end

    rows =
      if search not in [nil, ""] do
        search = String.downcase(search)

        Enum.filter(rows, fn row ->
          String.contains?(String.downcase(to_string(row[:search_table])), search) or
            String.contains?(String.downcase(to_string(row[:schema])), search)
        end)
      else
        rows
      end

    total = length(rows)

    rows =
      rows
      |> Enum.sort_by(&(&1[sort_by]), sort_dir)
      |> Enum.take(limit)

    {rows, total}
  end

  @doc false
  def table_statuses do
    Enum.map(Khafra.Observer.get_table_servers(), fn {schema, pid} ->
      try do
        state = GenServer.call(pid, :peek)

        state.table_status
        |> Map.put(:schema, inspect(schema))
        |> Map.put(:search_table, state.search_table)
      catch
        :exit, _ -> %{schema: inspect(schema), search_table: "unavailable"}
      end
    end)
  end
end
