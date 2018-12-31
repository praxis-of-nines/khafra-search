defmodule Khafra.ReleaseTasks do
  @moduledoc """
  Run tasks related to new or migrating systems
  """
  alias Khafra.Generate.GenerateFromConfig, as: Gen
  alias Khafra.Init.Tasks
  alias Khafra.Job.IndexOpts
  alias Khafra.Job.Searchd


  @doc """
  Download Sphinx and unpack it
  """
  def download_sphinx(), do: download_sphinx([])
  def download_sphinx([version]) do
    IO.puts "Downloading Sphinx (May take a while)"

    _ = Tasks.download_sphinx(version)

    IO.puts "Sphinx download and unpack complete"
  end

  @doc """
  Generate a sphinx configuration based on provided elixir config
  """
  def generate_config(), do: generate_config([])
  def generate_config([]) do
    Gen.gen_all()

    IO.puts "Finished Generating sphinx/sphinx.conf.  Run mix khafra.sphinx.index to test"
  end

  @doc """
  Run the indexer with options
  """
  def indexer(), do: indexer([])
  def indexer(opts) do
    result = IndexOpts.run(opts)

    IO.puts result
  end

  @doc """
  Run searchd
  """
  def searchd(), do: searchd([])
  def searchd(opts) do
    result = Searchd.run(opts)

    IO.puts result
  end
end