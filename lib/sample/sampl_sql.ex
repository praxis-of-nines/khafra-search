defmodule Khafra.Sample.SampleSQL do
  @moduledoc """
  Contains functions pertaining to testing functionality of Khafra. Aims to show
  how one might integrate khafra smoothly with their app using the SQL library
  instead of Ecto.
  """
  # `use SQL, pool: :default` reads the pool's adapter (Postgres in dev.exs) and
  # stores it on the module's `@sql_config`, so `~SQL` sigils in this module are
  # formatted with Postgres-flavored placeholders (`$1`, `$2`...) instead of the
  # ANSI default (`?`), which Postgres would reject with a syntax error.
  use SQL, pool: :default

  alias Giza.{ManticoreQL, SearchTables}
  alias Khafra.Sample.TestSql

  @table Atom.to_string(TestSql.table_name())

  @doc "Add book"
  def add_book(%{id: id, title: title, description: description}, _opts) do
    Enum.to_list(~SQL"INSERT INTO book (id, title, description) VALUES ({{id}}, {{title}}, {{description}})")

    SearchTables.replace(@table, ["id", "title", "description"], [id, title, description])
  end

  @doc "Update book"
  def update_book(id, %{title: title, description: description}, _opts) do
    Enum.to_list(~SQL"UPDATE book SET title = {{title}}, description = {{description}} WHERE id = {{id}}")

    SearchTables.replace(@table, ["id", "title", "description"], [id, title, description])
  end

  @doc "Retrieve a book"
  def get_book(id) do
    ~SQL"FROM book SELECT id, title, description WHERE id = {{id}}"
    |> Enum.to_list()
    |> List.first()
  end

  @doc "Find books from search tables"
  def find_books(search_string) do
    ManticoreQL.new()
    |> ManticoreQL.from("#{@table}_dist")
    |> ManticoreQL.match("*#{search_string}*")
    |> Giza.send!()
  end
end
