defmodule Khafra.SearchTable.TableSupervisor do
  @moduledoc """
  DynamicSupervisor that starts a TableServer for each manticore
  real-time table derived from modules implementing SearchBehaviour.
  """
  use DynamicSupervisor

  require Logger

  def start_link(init_arg) do
    {:ok, pid} = DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    
    start_table_servers()
    
    {:ok, pid}
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Called after the supervisor is started to spin up a TableServer
  for every schema that implements SearchBehaviour.
  """
  def start_table_servers do
    Enum.each(search_schemas(), fn schema ->
      case DynamicSupervisor.start_child(__MODULE__, {Khafra.SearchTable.TableServer, schema}) do
        {:ok, _pid} ->
          :ok

        {:error, reason} ->
          Logger.error("Failed to start TableServer for #{inspect(schema)}: #{inspect(reason)}")
      end
    end)
  end

  @doc """
  Return all loaded modules that implement Khafra.SearchBehaviour.
  """
  def search_schemas do
    :application.loaded_applications()
    |> Enum.flat_map(fn {app, _, _} ->
      case :application.get_key(app, :modules) do
        {:ok, modules} -> modules
        _ -> []
      end
    end)
    |> Enum.filter(&implements_search_behaviour?/1)
  end

  # PRIVATE FUNCTIONS
  ###################
  defp implements_search_behaviour?(module) do
    Code.ensure_loaded(module)

    module.module_info(:attributes)
    |> Keyword.get_values(:behaviour)
    |> List.flatten()
    |> Enum.member?(Khafra.SearchBehaviour)
  rescue
    _ -> false
  end
end