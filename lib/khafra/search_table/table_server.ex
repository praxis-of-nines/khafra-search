defmodule Khafra.SearchTable.TableServer do
  @moduledoc """
  GenServer representing a single manticore real-time table.
  """
  use GenServer

  @scope :search_tables

  def start_link(schema) do
    GenServer.start_link(__MODULE__, schema)
  end

  @impl true
  def init(schema) do
    :syn.register(@scope, {:table, schema}, self(), %{schema: schema})

    {:ok, %{schema: schema}}
  end

  @doc """
  Look up the pid for a table server by schema module.
  """
  def lookup(schema) do
    :syn.lookup(@scope, {:table, schema})
  end
end
