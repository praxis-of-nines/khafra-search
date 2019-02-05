# Khafra Search

Khafra allows you to easily deploy and maintain a search cluster similar to elastic search. You will want to use khafra if:

- You want to keep your deployments and tooling Elixir based and not learn how to maintain Sphinx
- You test and reindex your project often in development and wish to speed up your development cycle
- You find it messy to keep track of all the configuration files for projects over and over
- You wish to deploy Sphinx without configuring CRON jobs on the server
- You want to monitor sphinx from an Elixir or Phoenix project
- New to search indexing and want to learn!

Khafra is a dependency that can be added to any Elixir project or Phoenix Framework and uses Quantum to handle job execution schedules (for non-real time indexing use cases).

To query your running sphinx environment you can use the [Giza Sphinx Client for Elixir](https://hex.pm/packages/giza_sphinxsearch)


## Installation

```elixir
def deps do
  [
    {:khafra_search, "~> 0.1"}
  ]
end
```


## Getting Started

First up set some indexing config in your application to connect to your database and index a table:

```elixir
config :khafra_search, :source_sqldb,
  adapter: :postgres,
  database: "database_name",
  username: "db_user_name",
  password: "db_user_pass",
  hostname: "localhost"
```

```elixir
# Note the \\ newline deliminator for query strings
config :khafra_search, :source_person,
  parent: :source_sqldb,
  query: """
    SELECT id, name, company, title, updated_at \\
    FROM persons
  """,
  attributes: [
    updated_at: :datetime],
  fields: [
    name:    :string,
    company: :string,
    title:   :string
  ]

config :khafra_search, :i_person,
  parent: :index_defaults,
  source: :source_person

# Specifying indices to index allows to change which indexes are rotated per environment
config :khafra_search, 
  indices: [:i_person]
```

Now let's do a local Sphinx install and query some data

```elixir
# May take time depending on connection speed
> mix khafra.sphinx.download linux_64

> mix khafra.gen.sphinxconf

# Try out your config
> mix khafra.sphinx.index all

# Start the search daemon
> mix khafra.sphinx.searchd

# You can now query sphinx! (Recommendation: use the Giza Elixir search client).  Let's rotate the index while running
> mix khafra.sphinx.index rotate all
```

Rotating the index can be set on a schedule using the 'advanced' configuration options.  You should now be able to test locally and your deployment depends entirely on how you like to run your Elixir deployments.


## Advanced Configuration

Configure the indexer to rotate once per day (see [Quantum](https://hexdocs.pm/quantum/readme.html) for more details):

```elixir
config :khafra_search, Khafra.Scheduler,
  timezone: "America/Los_Angeles",
  global: true,
  timeout: :infinity,
  jobs: [
    {"* * * * *", {Khafra.Job.Index, :run, [
      [{:option, "--rotate"}, {:option, "--all"}]
    ]}},
    {"@daily", {Khafra.Job.Index, :run, [{:option, "--rotate"}, {:option, "--all"}]}}
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


## Needed features:

- Generators for some of the deployment tasks that are useful. For example when using distillery you probably want to set these commands up:

```
#!/bin/sh

release_ctl eval --mfa "Khafra.ReleaseTasks.download_sphinx/1" --argv -- "$@"
```
```
#!/bin/sh

release_ctl eval --mfa "Khafra.ReleaseTasks.generate_config/1" --argv -- "$@"
```
```
#!/bin/sh

release_ctl eval --mfa "Khafra.ReleaseTasks.indexer/1" --argv -- "$@"
```
```
#!/bin/sh

release_ctl eval --mfa "Khafra.ReleaseTasks.searchd/1" --argv -- "$@"
```
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