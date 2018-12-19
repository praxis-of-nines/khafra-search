defmodule Mix.Tasks.Khafra.Sphinx.Searchd do
  use Mix.Task

  @shortdoc "Shortcut to run the Sphinx Search Daemon"

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

  def run([]), do: run_searchd_command(["-c", "../../sphinx.conf"])
  def run(["stop"]), do: run_searchd_command(["-c", "../../sphinx.conf", "--stop"])
  def run(["status"]), do: run_searchd_command(["-c", "../../sphinx.conf", "--status"])

  def run(["windows"]), do: run_searchd_command("./searchd.exe", ["-c", "../../sphinx.conf"])
  def run(["windows","stop"]), do: run_searchd_command("./searchd.exe", ["-c", "../../sphinx.conf", "--stop"])
  def run(["windows","status"]), do: run_searchd_command("./searchd.exe", ["-c", "../../sphinx.conf", "--status"])

  def run_searchd_command(params), do: run_searchd_command("searchd", params)

  def run_searchd_command(exe_file_name, params) do
    _ = File.mkdir("sphinx/data")
    _ = File.mkdir("sphinx/log")

    {result, _} = System.cwd
    |> Path.join("sphinx/install/bin/./" <> exe_file_name)
    |> System.cmd(params, cd: "sphinx/install/bin")

    Mix.shell.info result
  end
end