defmodule Mix.Tasks.Khafra.Sphinx.Index do
  use Mix.Task

  @shortdoc "Shortcut to run the Sphinx Indexer"

  @moduledoc """
  Mix shortcut to running the Sphinx Indexer to build an index against the data source.

  Options:

  Called without argument, indexer will run all indexes.  If you want to re-run the indexes while
  searchd is running, use rotate as a first option and you will seamlessly rotate the new indexes in.

  You can also append options that will override all and index only specific indexes.

  ## Example
      # Rotates all indices
      > mix khafra.sphinx.index rotate

      # Rotates the listed indices
      > mix khafra.sphinx.index rotate blog_posts blog_authors

      > mix khafra.sphinx.index only blog_posts
    
      # Windows machines must run their own version of the command
      > mix khafra.win.sphinx.index rotate
  """

  def run([]), do: run_command(["-c", "../../sphinx.conf", "--all"])

  def run(["rotate"|options]) do
    indices = case options do
      [] ->
        ["--all"]
      _ ->
        options
    end

    run_command(["-c", "../../sphinx.conf", "--rotate"|indices])
  end

  def run(["only"|indices]) do
    run_command(["-c", "../../sphinx.conf"] ++ indices)
  end

  def run(["windows"]), do: run_command("indexer.exe", ["-c", "../../sphinx.conf", "--all"])

  def run(["windows", "rotate"|options]) do
    indices = case options do
      [] ->
        ["--all"]
      _ ->
        options
    end

    run_command("indexer.exe", ["-c", "../../sphinx/sphinx.conf", "--rotate"|indices])
  end

  def run(["windows"|indices]), do: run_command("indexer.exe", ["-c", "../../sphinx.conf"] ++ indices)


  defp run_command(options), do: run_command("indexer", options)

  defp run_command(exe_file_name, options) do
    _ = File.mkdir("sphinx/data")

    {result, _} = System.cwd()
    |> Path.join("sphinx/install/bin/./" <> exe_file_name)
    |> System.cmd(options, cd: "sphinx/install/bin")

    Mix.shell.info result

    Mix.shell.info "Indexing complete"
  end
end