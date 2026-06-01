# Khafra Search

Khafra has changed from a deployment handler search clusters to managing real time search
data in a cluster based on Ecto & SQL schemas and behaviours.

Features:

  * Implements core functionality of Manticore & Sphinx Search through Giza
  * Behaviour to back your [Ecto Schemas](https://hexdocs.pm/ecto/Ecto.html) with search tables
  * Behaviour to back [SQL tables](https://github.com/elixir-dbvisor/sql) with search tables
  * Automated distributed table creation
  * Timed and executable tasks for refreshing search data
  * RabbitMQ queue supported for mass distributed updates

Khafra includes the [Giza Sphinx Client for Elixir](https://hex.pm/packages/giza_sphinxsearch) 


## Installation

```elixir
def deps do
  [
    {:khafra_search, "~> 0.3"}
  ]
end

# Add to your application or supervisor
def start(_type, _args) do
    import Supervisor.Spec

    children = [
      ...,
      Khafra.Supervisor
    ]

    opts = [strategy: :one_for_one, name: YourApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
```

### Optional

Install RabbitMQ to enable queuing operations. This is the only supported queue for now.

The default is streaming or immediate operations so queueing is not necessary.

## Search Behaviours

Khafra exposes two behaviours that mark a module as backable by a real-time
search table. Implement one of them on the schema/module that represents your
data, and Khafra will create a matching Manticore table on startup and keep it
in sync as rows are inserted or updated through `Khafra.insert/2` and
`Khafra.update/2`.

### `Khafra.SearchBehaviour` (Ecto)

For modules using `Ecto.Schema`. The behaviour requires a single callback,
`index_fields/0`, returning the list of schema fields that should be indexed
for full-text search. The schema's `@source` (table name) is used to derive
the Manticore table and its `_dist` distributed alias.

```elixir path=dev_support/sample/test_schema.ex start=1
defmodule Khafra.Sample.TestSchema do
  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Khafra.SearchBehaviour

  schema "test" do
    field :city, :string
    field :temp_lo, :integer
    field :temp_hi, :integer
    field :score, :float
    field :desc, :string

    timestamps()
  end

  def changeset(test, attrs) do
    cast(test, attrs, [:city, :temp_lo, :temp_hi, :score, :desc])
  end

  @impl Khafra.SearchBehaviour
  def index_fields, do: [:city, :desc]
end

```
### `Khafra.SearchBehaviourSQL` (`~SQL` sigil)

For modules built on the [`elixir-dbvisor/sql`](https://github.com/elixir-dbvisor/sql)
library instead of Ecto. Two callbacks are required:
  * `table_name/0` &mdash; the underlying SQL table name as an atom
  * `index_fields/0` &mdash; a `Keyword.t()` of `field: type` pairs to index

```elixir path=dev_support/sample/test_sql.ex start=1
defmodule Khafra.Sample.TestSql do
  @behaviour Khafra.SearchBehaviourSQL

  @impl Khafra.SearchBehaviourSQL
  def table_name, do: :book

  @impl Khafra.SearchBehaviourSQL
  def index_fields, do: [id: :integer, title: :string, description: :string]
end
```

## Search Examples

The modules under `dev_support/sample/` show the basics for how Khafra is intended to
be wired into an application. Two complete samples are included &mdash; one driven by
Ecto (`Khafra.Sample`) and one driven by `~SQL` (`Khafra.Sample.SampleSQL`). They are
compiled only in `:dev` and `:test` and are not shipped in the published package.

### Ecto example

`Khafra.insert/2` and `Khafra.update/2` accept the result of a normal Ecto
operation and, when the schema implements `Khafra.SearchBehaviour`,
transparently mirror the row into the Manticore real-time table.

```elixir path=dev_support/sample/sample.ex start=11
def add_city(%{} = attrs, opts) do
  %TestSchema{}
  |> TestSchema.changeset(attrs)
  |> @repo.insert()
  |> Khafra.insert(opts)
end

def update_city(city, %{} = attrs, opts) do
  city
  |> TestSchema.changeset(attrs)
  |> @repo.update()
  |> Khafra.update(opts)
end

def find_cities(search_string) do
  ManticoreQL.new()
  |> ManticoreQL.from("test_dist")
  |> ManticoreQL.match("*#{search_string}*")
  |> Giza.send()
end
```

A convenience path is also available through `Khafra.match/2`, which accepts
either an Ecto query struct or a `%SQL{}` struct and dispatches to the right
distributed table:

```elixir path=null start=null
Khafra.match(from t in TestSchema, where: t.city == "Tokyo")
```

### `~SQL` example

When using the `~SQL` sigil, `Khafra.SearchBehaviourSQL` is paired with
`Giza.SearchTables.replace/3` to push rows into Manticore alongside the
primary write. `Khafra.match/2` understands `%SQL{}` structs directly and
translates `WHERE field = 'value'` predicates into Manticore `MATCH`
expressions against the `_dist` table.

```elixir path=dev_support/sample/sampl_sql.ex start=18
def add_book(%{id: id, title: title, description: description}, _opts) do
  Enum.to_list(
    ~SQL"INSERT INTO book (id, title, description) VALUES ({{id}}, {{title}}, {{description}})"
  )

  SearchTables.replace(@table, ["id", "title", "description"], [id, title, description])
end

def find_books(search_string) do
  ManticoreQL.new()
  |> ManticoreQL.from("#{@table}_dist")
  |> ManticoreQL.match("*#{search_string}*")
  |> Giza.send!()
end
```

### Other useful entry points

  * `Khafra.create_table/2` &mdash; create the Manticore table for a schema
    using the configured strategy
  * `Khafra.refresh_table/2` &mdash; rebuild the search table from the
    underlying datastore (batched/streamed; see
    `Khafra.SearchTable.batch_replace/2`)
  * `Khafra.trigger_maintenance/0` &mdash; force a maintenance pass on every
    registered table server (also runs daily via `Khafra.Scheduler`)
  * `Khafra.peek/1` and `Khafra.peek/2` &mdash; inspect observer and
    per-table state
  * `Khafra.destroy_all/0` &mdash; drop every managed table and its
    distributed index on the current node (intended for tests)

## Live Dashboard

Khafra ships with two [Phoenix LiveDashboard](https://hexdocs.pm/phoenix_live_dashboard/)
pages for observing search activity in real time. Mount them through the
`additional_pages` option of `live_dashboard` in your router:

```elixir path=null start=null
live_dashboard "/dashboard",
  additional_pages: [
    search_tables: Khafra.LiveDashboard.SearchTablesPage,
    query_metrics: Khafra.LiveDashboard.QueryMetricsPage
  ]
```

### `Khafra.LiveDashboard.SearchTablesPage`

Lists every Manticore table managed by Khafra on the selected node, with
sortable/searchable columns for the table name, the backing schema, indexed
document count, RAM footprint and on-disk size. Data is sourced live from
the `Khafra.Observer` registry of `TableServer` processes via `:rpc`, so the
page reflects whichever node you are inspecting.

### `Khafra.LiveDashboard.QueryMetricsPage`

Renders live charts driven by Giza's `[:giza, :query, :stop]` and
`[:giza, :query, :exception]` telemetry events:
  * Query Count (counter)
  * Query Duration (summary, ms)
  * Query Errors (counter)
  * Duration by Source (summary, ms, broken down by query source tag)
Metrics are scoped per LiveDashboard session &mdash; the page attaches its
own telemetry handler on `mount/3` and tears it down when the socket
disconnects.

