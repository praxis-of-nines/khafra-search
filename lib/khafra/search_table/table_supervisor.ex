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
  for every schema that implements SearchBehaviour or SearchBehaviourSQL.
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

    Enum.each(sql_modules(), fn module ->
      case DynamicSupervisor.start_child(__MODULE__, {Khafra.SearchTable.TableServer, {:sql, module}}) do
        {:ok, _pid} ->
          :ok

        {:error, reason} ->
          Logger.error("Failed to start TableServer for SQL module #{inspect(module)}: #{inspect(reason)}")
      end
    end)
  end

  @doc """
  Return all loaded modules that implement Khafra.SearchBehaviour.
  """
  def search_schemas do
    all_modules()
    |> Enum.filter(&implements_behaviour?(&1, Khafra.SearchBehaviour))
  end

  @doc """
  Return all loaded modules that implement Khafra.SearchBehaviourSQL.
  """
  def sql_modules do
    all_modules()
    |> Enum.filter(&implements_behaviour?(&1, Khafra.SearchBehaviourSQL))
  end

  # PRIVATE FUNCTIONS
  ###################
  defp all_modules do
    :application.loaded_applications()
    |> Enum.flat_map(fn {app, _, _} ->
      case :application.get_key(app, :modules) do
        {:ok, modules} -> modules
        _ -> []
      end
    end)
  end

  defp implements_behaviour?(module, behaviour) do
    Code.ensure_loaded(module)

    module.module_info(:attributes)
    |> Keyword.get_values(:behaviour)
    |> List.flatten()
    |> Enum.member?(behaviour)
  rescue
    _ -> false
  end
end
