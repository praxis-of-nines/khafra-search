defmodule Mix.Tasks.Khafra.Sphinx.Searchd do
  use Mix.Task

  @shortdoc "Shortcut to run the Sphinx Search Daemon"

  alias Khafra.Job.Searchd

  @moduledoc """
  Mix shortcut to running the Sphinx Search Daemon to run queries against.

  Options:

  Running without option will start searchd, while stop will stop the service.
  Other options are to run for a windows machine.

  ## Example

      > mix khafra.sphinx.searchd

      > mix khafra.sphinx.searchd stop

      > mix khafra.win.sphinx.searchd
    
      > mix khafra.win.sphinx.searchd stop
  """

  def run(opts) do
    result = Searchd.run(opts)

    Khafra.output_stream_command_result(result)
  end
end