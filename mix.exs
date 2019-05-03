defmodule Khafra.MixProject do
  use Mix.Project

  def project do
    [
      app: :khafra_search,
      version: "0.1.4",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: description(),
      package: package()
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
      {:simplestatex, "~> 0.1.6"}
    ]
  end

  defp aliases do
    [
      "khafra.win.sphinx.searchd": ["khafra.sphinx.searchd windows"],
      "khafra.win.sphinx.index": ["khafra.sphinx.index windows"]
    ]
  end

  defp description() do
    "A search deployment helper library. Aims to bring distributed Sphinx up to the ease of deployment and use of elastic search."
  end

  defp package() do
    [
      licenses: ["MIT"],
      maintainers: ["Tyler Pierce"],
      files: ["lib", "mix.exs", "README.md", "test", "config"],
      links: %{"GitHub" => "https://github.com/praxis-of-nines/khafra-search"},
      source_url: "https://github.com/praxis-of-nines/khafra-search"
    ]
  end
end
