defmodule Khafra.SearchTable do
  @moduledoc """
  Search Table methods
  """
  alias Khafra.SearchTable.{BatchOperations, Operations}

  @doc """
  Insert or update a table row
  """
  def replace(entity, opts \\ []) do
    Operations.replace(entity, Keyword.get(opts, :strategy))
  end

  @doc """
  Run a batch of replace operations using the provided strategy
  """
  def batch_replace(query, opts \\ []) do
    BatchOperations.batch_update(
      query,
      &replace/1,
      Keyword.get(opts, :strategy, :stream)
    )
  end

  @doc """
  Create a table modifying by provided opts.
  """
  def create(schema, opts \\ [])

  def create(schema, opts) do
    # merge opts with default create opts
    {table_type, opts} = default_create_opts()
                         |> Keyword.merge(opts)
                         |> Keyword.pop!(:type)

    
    Operations.create(schema, table_type, opts)
  end

  # PRIVATE FUNCTIONS
  ###################
  defp default_create_opts do
    [
      {:type, :rt},
      {:fuzzy_match, true}
    ]
  end
end
