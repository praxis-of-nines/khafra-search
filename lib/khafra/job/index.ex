defmodule Khafra.Job.Index do
  def run(opts) do
    conf_path = System.cwd()
    |> Path.join("sphinx/sphinx.conf")

    run(["-c", conf_path], "linux", opts)
  end

  def run(command_opts, system, [{:indices, indices}|opts]) do
    indices = Enum.reduce(indices, [], fn index, acc ->
      [Atom.to_string(index)|acc]
    end)

    run(command_opts ++ indices, system, opts)
  end

  def run(command_opts, system, [{:option, option}|opts]) do
    run([option|command_opts], system, opts)
  end

  def run(command_opts, _, []), do: run_command("indexer", command_opts)

  defp run_command(exe_name, options) do
    System.cwd()
    |> Path.join("/sphinx/install/usr/bin/./" <> exe_name)
    |> System.cmd(options)
  end
end