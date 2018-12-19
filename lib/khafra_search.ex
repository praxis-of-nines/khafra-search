defmodule Khafra do
  @moduledoc """
  Khafra: The distributed search deployment platform
  """

  alias SimpleStatEx, as: SSX

  @doc """
  Take a query string and return the command params to run the query from the
  command line
  TODO: use Giza for this
  """
  def cmd_query_params(query), do: ["-h", "127.0.0.1", "-P", "9306", "-e", query]

  @doc """
  Get a stat dump of how many times the index rotation job has been run
  """
  def stat_index_rotate() do
    SSX.query("indexer", :daily) |> SSX.memory() |> SSX.get()
  end
end
