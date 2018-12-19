defmodule Khafra.MixProject do
  use Mix.Project

  def project do
    [
      app: :khafra_search,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:edeliver, ">= 1.6.0"},
      {:distillery, "~> 2.0"},
      {:quantum, "~> 2.3"},
      {:timex, "~> 3.0"},
      {:simplestatex, "~> 0.1.5"},
      {:giza_sphinxsearch, path: "../giza_sphinxsearch"}
      #{:giza_sphinxsearch, "~> 1.0"}
    ]
  end

  defp aliases do
    [
      "khafra.win.sphinx.searchd": ["khafra.sphinx.searchd windows"],
      "khafra.win.sphinx.index": ["khafra.sphinx.index windows"]
    ]
  end
end
