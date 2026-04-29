defmodule Khafra.MixProject do
  use Mix.Project

  def project do
    [
      app: :khafra_search,
      version: "0.3.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: description(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger], mod: {Khafra.Application, []}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:quantum, "~> 3.0"},
      {:giza_sphinxsearch, "~> 2.1.1"},
      {:syn, "~> 3.4"},
      {:lapin, "~> 2.0.0"},
      {:phoenix_live_dashboard, "~> 0.8", optional: true},
      {:ecto, "~> 3.13"},
      {:ecto_sql, "~> 3.12"},
      {:postgrex, "~> 0.22"},
      {:sql, "~> 0.5.0"}
    ]
  end

  defp aliases do
    []
  end

  defp description() do
    """
    A search deployment helper library. Aims to easy deployment and monitoring of 
    distributed Manticore & Sphinx in a Linux environment
    """
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
