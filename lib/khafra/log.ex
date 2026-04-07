defmodule Khafra.Log do
  @moduledoc """
  All logging related to Khafra. All functions are pass-through
  """
  # require Logger

  @doc "Log an upsert result"
  def replace(result) do
    IO.inspect(result)
  end

  @doc "Log a batch operation return"
  def batch_operation(result) do
    IO.inspect(result)
  end

  @doc "Log a create table request"
  def create_table(result) do
    IO.inspect(result)
  end
end
