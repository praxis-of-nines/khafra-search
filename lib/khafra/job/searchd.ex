defmodule Khafra.Job.Searchd do
  def run([]), do: run_searchd_command(["-c", "../../../sphinx.conf"])
  def run(["stop"]), do: run_searchd_command(["-c", "../../../sphinx.conf", "--stop"])
  def run(["status"]), do: run_searchd_command(["-c", "../../../sphinx.conf", "--status"])

  def run_searchd_command(params), do: run_searchd_command("searchd", params)

  def run_searchd_command(exe_file_name, params) do
    _ = File.mkdir("sphinx/data")
    _ = File.mkdir("sphinx/log")

    System.cwd()
    |> Path.join("sphinx/install/usr/bin/./" <> exe_file_name)
    |> System.cmd(params, cd: "sphinx/install/usr/bin")
  end
end