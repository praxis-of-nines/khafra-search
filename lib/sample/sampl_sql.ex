defmodule Khafra.Sample.SampleSQL do
  @moduledoc """
  Contains functions pertaining to testing functionality of Khafra. Aims to show
  how one might integrate khafra smoothly with their app using the SQL library
  instead of Ecto.
  """
  import SQL

  alias Giza.{ManticoreQL, SearchTables}
  alias Khafra.Sample.TestSql

  @table Atom.to_string(TestSql.table_name())

  @doc "Add book"
  def add_book(%{title: title, description: description}, _opts) do
    Enum.to_list(~SQL"INSERT INTO books (title, description) VALUES ({{title}}, {{description}})")

    SearchTables.replace(@table, ["title", "description"], [title, description])
  end

  @doc "Update book"
  def update_book(book_id, %{title: title, description: description}, _opts) do
    Enum.to_list(~SQL"UPDATE books SET title = {{title}}, description = {{description}} WHERE id = {{book_id}}")

    SearchTables.replace(@table, ["id", "title", "description"], [book_id, title, description])
  end

  @doc "Retrieve a book"
  def get_book(id) do
    ~SQL"FROM books SELECT id, title, description WHERE id = {{id}}"
    |> Enum.to_list()
    |> List.first()
  end

  @doc "Find books from search tables"
  def find_books(search_string) do
    ManticoreQL.new()
    |> ManticoreQL.from("#{@table}_dist")
    |> ManticoreQL.match("*#{search_string}*")
    |> Giza.send()
  end
end
