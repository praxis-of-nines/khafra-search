defmodule Khafra.Job.IndexOpts do
  @moduledoc """
  Run through command line options and convert them to full option list for Index job.
  """
  alias Khafra.Job.Index, as: IndexJob


  def run(cmd_opts), do: run(cmd_opts, [], [])

  def run(["all"|cmd_opts], indices, opts) do
    run(cmd_opts, indices, [{:option, "--all"}|opts])
  end

  def run(["rotate"|cmd_opts], indices, opts) do
    run(cmd_opts, indices, [{:option, "--rotate"}|opts])
  end

  def run([index|cmd_opts], indices, opts) do
    run(cmd_opts, [index|indices], opts)
  end

  def run([], [], opts) do
    IndexJob.run(opts)
  end

  def run([], indices, opts) do
    IndexJob.run([{:indices, indices}|opts])
  end
end