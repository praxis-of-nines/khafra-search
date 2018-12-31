defmodule Mix.Tasks.Khafra.Sphinx.Index do
  use Mix.Task

  @shortdoc "Shortcut to run the Sphinx Indexer"

  alias Khafra.Job.IndexOpts

  @moduledoc """
  Mix shortcut to running the Sphinx Indexer to build an index against the data source.

  Options:

  Called without argument, indexer will run all indexes.  If you want to re-run the indexes while
  searchd is running, use rotate as a first option and you will seamlessly rotate the new indexes in.

  You can also append options that will override all and index only specific indexes.

  ## Example
      # Rotates all indices
      > mix khafra.sphinx.index rotate all

      # Rotates the listed indices
      > mix khafra.sphinx.index rotate blog_posts blog_authors

      > mix khafra.sphinx.index blog_posts
    
      # Windows machines must run their own version of the command
      > mix khafra.win.sphinx.index rotate all
  """
  def run(opts) do
    result = IndexOpts.run(opts)

    Khafra.output_stream_command_result(result)
  end
end