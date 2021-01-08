defmodule Khafra.Init.Tasks do
  @moduledoc """
  A group of tasks related to initialization, or a first time run, of Sphinx Search
  """
  alias Khafra.Generate.GenerateFromConfig, as: Gen

  @linux_64_version "manticore-3.5.4-201211-13f8d08-release-source"
  @windows_64_version "sphinx-3.1.1-612d99f-windows-amd64.zip"
  @mac_os_version "sphinx-3.1.1-612d99f-darwin-amd64"

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
  def download_sphinx("windows_64"), do: download_sphinx("windows_64", @windows_64_version)
  def download_sphinx("mac"), do: download_sphinx("mac", @mac_os_version)

  def download_sphinx(version_type, version) do
    _ = File.mkdir("sphinx/install")
    # Create the recommended data/logging dirs
    _ = File.mkdir("sphinx/data")
    _ = File.mkdir("sphinx/log")

    download = download(version)

    unpack = unpack(version_type, version)

    remove = remove()

    [download, unpack, remove]
  end

  def start_searchd(os \\ :linux) do
    searchd(["-c", "../../sphinx.conf"], os)
  end

  def stop_searchd(os \\ :linux) do
    searchd(["-c", "../../sphinx.conf", "--stop"], os)
  end

  def searchd(params, os \\ :linux) do
    _ = File.mkdir("sphinx/data")
    _ = File.mkdir("sphinx/log")

    exe_file_name = case os do
      :win -> "searchd.exe"
      _ -> "searchd"
    end

    System.cwd
    |> Path.join("sphinx/install/bin/./" <> exe_file_name)
    |> System.cmd(params, cd: "sphinx/install/bin")
  end

  defp download(version) do
    _ = File.mkdir("sphinx/install")

    System.cmd(
      "wget", 
      ["-q", "https://repo.manticoresearch.com/repository/manticoresearch_source/release/#{version}.tar.gz", "-P", "sphinx/install/"])
  end

  defp remove() do
    System.cmd("rm", ["-rf", "sphinxdata"], cd: "sphinx/install/bin")
  end

  defp unpack("mac_os", version), do: unpack("linux_64", version)

  defp unpack("linux_64", version) do
    System.cmd(
      "tar", 
      ["zxf", "sphinx/install/#{version}.tar.gz", "-C", "sphinx/install", "--strip-components", "1"])
  end

  defp unpack("windows_64", version) do
    System.cmd(
      "unzip", 
      ["sphinx/install/#{version}.zip"])
  end
end