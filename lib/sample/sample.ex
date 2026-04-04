defmodule Khafra.Sample do
  @moduledoc """
  Contains functions pertaining to testing functionality of Khafra. Aims to show
  how one might integrate khafra smoothly with their app
  """
  alias Giza.ManticoreQL
  alias Khafra.Sample.Repo
  alias Khafra.Sample.TestSchema

  @doc "Add city"
  def add_city(%{} = attrs) do
    %TestSchema{}
    |> TestSchema.changeset(attrs)
    |> Repo.insert()
    |> Khafra.insert()
  end

  @doc "Update city"
  def update_city(city, %{} = attrs) do
    city
    |> TestSchema.changeset(attrs)
    |> Repo.update()
    |> Khafra.update()
  end

  @doc "Retrieve a city"
  def get_city(id) do
    Repo.get_by(TestSchema, id: id)
  end

  @doc "Find cities from search tables"
  def find_cities(search_string) do
    ManticoreQL.new()
    |> ManticoreQL.from("testschema")
    |> ManticoreQL.match("*#{search_string}*")
    |> Giza.send()
  end
end
