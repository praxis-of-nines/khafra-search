defmodule Mix.Tasks.Khafra.Gen.Sphinxconf do
  use Mix.Task

  @shortdoc "Generate the Sphinx config based on Khafra settings"

  @moduledoc """
  When you create your index settings in config/sphinx.exs (and any env conf files you wish) they can
  be used to generate a config that sphinx daemon and indexer use.  Re-generate this any time to test
  your sphinx settings locally.

  ## Example

      > mix khafra.gen.sphinxconf
  """
  alias Khafra.Generate.GenerateFromConfig, as: Gen

  def run([]) do
    Gen.gen_all()

    Mix.shell.info "Finished Generating sphinx/sphinx.conf.  Run mix khafra.sphinx.index to test"
  end
end