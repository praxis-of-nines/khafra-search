defmodule Khafra.Job.RotateIndex do
  alias SimpleStatEx, as: SSX

  def run(indices) do
    indices = Enum.reduce(indices, [], fn index, acc ->
      [Atom.to_string(index)|acc]
    end)

    run_command("indexer", ["-c", "../../sphinx.conf", "--rotate"|indices])
  end

  def win_run(indices) do
    indices = Enum.reduce(indices, [], fn index, acc ->
      [Atom.to_string(index)|acc]
    end)

    run_command("indexer.exe", ["-c", "../../sphinx.conf", "--rotate"|indices])
  end

  def run() do
    run_command("indexer", ["-c", "../../sphinx.conf", "--rotate", "--all"])
  end

  def win_run() do
    run_command("indexer.exe", ["-c", "../../sphinx.conf", "--rotate", "--all"])
  end

  defp run_command(exe_name, options) do
    _ = System.cwd()
    |> Path.join("sphinx/install/bin/./" <> exe_name)
    |> System.cmd(options, cd: "sphinx/install/bin")

    SSX.stat("indexer", :daily) |> SSX.memory() |> SSX.save()
  end
end