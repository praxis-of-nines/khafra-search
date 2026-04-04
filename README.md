# Khafra Search

Khafra allows you to easily deploy and run Manticore or Sphinx in an Elixir deployment. The idea is eventually to create a managed cluster similar to ElasticSearch.

The project has shifted to focusing on real time tables and latest modern updates to Manticore & Sphinx and only 
testing on linux (dropping windows and other).

You will want to use khafra if:

- You want to keep your deployments and tooling Elixir based and not learn how to maintain Sphinx or Manticore
- And monitor Sphinx/Manticore from an Elixir project

Note that the search daemon and files Sphinx relies on will be deployed so you will have a non Elixir service
running. Sphinx is a battle tested C++ project and many may prefer to have a separate cluster for large search
needs. This project is about being a fast and easy to configure as possible and is aimed at running along-side
your app, but it isn't a requirement.

To query your running sphinx environment you can use the [Giza Sphinx Client for Elixir](https://hex.pm/packages/giza_sphinxsearch)


## Installation

```elixir
def deps do
  [
    {:khafra_search, "~> 0.2"}
  ]
end

# Add to your application or supervisor
def start(_type, _args) do
    import Supervisor.Spec

    # List all child processes to be supervised
    children = [
      ...,
      supervisor(Khafra.Supervisor, [])
    ]

    opts = [strategy: :one_for_one, name: YourApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
```


## Getting Started

You will want to update search tables as your source of truth (postgres or other) updates. To do so several
strategies are available.

TODO


## Advanced Configuration

Configure to optimize real time tables each night:

```elixir
config :khafra_search, Khafra.Scheduler,
  timezone: "America/Los_Angeles",
  global: true,
  timeout: :infinity,
  jobs: [
    {"0 22 * * *", {Khafra.Job.TableOptimize, :run, [
      [{:option, "--all"}]
    ]}}
  ]
```

Configure other indexer defaults + generate wordforms (see [Sphinx Docs](http://sphinxsearch.com/docs/manual-2.3.2.html#conf-wordforms) for details):

```elixir
# Note the cwd! keyword so the generator uses an absolute path for all of your environments
config :khafra_search, :index_defaults,
  type: "plain",
  source: {:sql, :source_sqldb},
  morphology: "none",
  min_stemming_len: "1",
  min_word_len: "1",
  min_infix_len: "2",
  html_strip: "0",
  preopen: "0",
  wordforms: "[cwd!]/sphinx/wordforms.txt"

> mix khafra.gen.wordform "s02e02" "season 2 episode 2"

> mix khafra.sphinx.index rotate all
```

## Deployment Example

Coming soon



And in your rel/config.exs
```
environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"some complicated cookie"
  set commands: [
    index: "rel/commands/indexer.sh",
    searchd: "rel/commands/searchd.sh",
    gen_config: "rel/commands/gen_config.sh",
    download_sphinx: "rel/commands/download_sphinx.sh"
  ]
end
```

- Helpers for distributed indexes so that a cluster knows exactly what to do without more specific instructions and sphinx configuration

- Testing and helpers to maintain a real time sphinx index

- Mix tasks to generate configuration with sensible defaults (possibly directly from postgres/mysql table data?)

- Monitoring tools and optional UI

- Heartbeat and monitoring logic
