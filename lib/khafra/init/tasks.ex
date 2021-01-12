defmodule Khafra.Init.Tasks do
  @moduledoc """
  A group of tasks related to initialization, or a first time run, of Sphinx Search
  """
  alias Khafra.Generate.GenerateFromConfig, as: Gen

  @version "manticore_3.5.4-201211-13f8d08d_amd64"
  @linux_64_version "https://repo.manticoresearch.com/repository/manticoresearch_focal/pool/m/manticore/manticore_3.5.4-201211-13f8d08d_amd64.deb"

  def all(version, os \\ :linux) do
    gen_all = generate_config()

    dl_sphinx = download_sphinx(version)

    start_searchd = start_searchd(os)

    [gen_all, dl_sphinx, start_searchd]
  end

  def generate_config() do
    Gen.gen_all()
  end

  def download_sphinx("linux_64"), do: download_sphinx("linux_64", @linux_64_version)

  def download_sphinx(_version_type, version) do
    _ = File.mkdir("sphinx/install")
    # Create the recommended data/logging dirs
    _ = File.mkdir("sphinx/data")
    _ = File.mkdir("sphinx/log")

    download = download(version)

    unpack = unpack()

    remove = remove()

    [download, unpack, remove]
  end

  def start_searchd(os \\ :linux) do
    searchd(["-c", "../../../sphinx.conf"], os)
  end

  def stop_searchd(os \\ :linux) do
    searchd(["-c", "../../../sphinx.conf", "--stop"], os)
  end

  def searchd(params, _os \\ :linux) do
    _ = File.mkdir("sphinx/data")
    _ = File.mkdir("sphinx/log")

    File.cwd()
    |> Path.join("sphinx/install/usr/bin/./searchd")
    |> System.cmd(params, cd: "sphinx/install/usr/bin")
  end

  defp download(version) do
    _ = File.mkdir("sphinx/install")

    System.cmd(
      "wget", 
      ["-q", version, "-P", "sphinx/install/"])
  end

  defp remove() do
    System.cmd("rm", ["-rf", "sphinxdata"], cd: "sphinx/install/bin")
  end

  defp unpack() do
    System.cmd(
      "tar", 
      ["zxf", "sphinx/install/#{@version}", "-C", "sphinx/install", "--strip-components", "1"])
  end
end