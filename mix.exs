defmodule Khafra.MixProject do
  use Mix.Project

  def project do
    [
      app: :khafra_search,
      version: "0.3.3",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: description(),
      package: package()
    ]
  end

  # `dev_support/` holds the bundled Ecto/`~SQL` examples that exercise the
  # library locally. They are intentionally excluded from `:prod` (and from
  # the published hex package) so consumers don't compile against
  # `Application.compile_env(:khafra_search, :repo)` or pull in extra deps.
  defp elixirc_paths(env) when env in [:dev, :test], do: ["lib", "dev_support"]
  defp elixirc_paths(_), do: ["lib"]

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
      files: ["lib", "mix.exs", "README.md", "config"],
      links: %{"GitHub" => "https://github.com/praxis-of-nines/khafra-search"},
      source_url: "https://github.com/praxis-of-nines/khafra-search"
    ]
  end
end
