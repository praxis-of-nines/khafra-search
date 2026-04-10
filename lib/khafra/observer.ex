defmodule Khafra.Observer do
  @moduledoc """
  Interface for the table observer which oversees table state management
  """
  alias Khafra.SearchTable.TableObserver

  @doc """
  Trigger jigged maintenance on all registered table servers
  """
  def trigger_maintenance, do: GenServer.cast(TableObserver, :maintain_all)

  @doc """
  Retrieve all schemas that implement search behaviour
  """
  def get_schemas do
    TableObserver
    |> GenServer.call(:peek)
    |> Map.get(:schemas)
  end

  @doc """
  Retrieve all schemas that implement search behaviour
  """
  def get_table_servers do
    TableObserver
    |> GenServer.call(:peek)
    |> Map.get(:tables)
  end
end
