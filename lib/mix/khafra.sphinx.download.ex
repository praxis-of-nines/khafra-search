defmodule Mix.Tasks.Khafra.Sphinx.Download do
  use Mix.Task

  alias Khafra.Init.Tasks

  @shortdoc "Download Sphinx source with binaries for given system"

  @moduledoc """
  Mix shortcut to downloading Sphinx for your system.  Pass the desired system using options shown
  below.

  Options:

  The system you wish to download for.  Downloads will go to sphinx/install/ relative to your project
  directory.

  ## Example

      > mix khafra.sphinx.download linux_64
      > mix khafra.sphinx.download windows_64
      > mix khafra.sphinx.download mac
  """
  def run([version]) do

    Mix.shell.info "Downloading Sphinx (May take a while)"

    _ = Tasks.download_sphinx(version)

    Mix.shell.info "Sphinx download and unpack complete"
  end
end