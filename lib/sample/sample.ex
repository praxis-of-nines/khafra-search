defmodule Khafra.Sample do
  @moduledoc """
  Contains functions pertaining to testing functionality of Khafra. Aims to show
  how one might integrate khafra smoothly with their app
  """
  alias Giza.ManticoreQL
  alias Khafra.Sample.TestSchema

  @repo Application.compile_env(:khafra_search, :repo)

  @doc "Add city"
  def add_city(%{} = attrs, opts) do
    %TestSchema{}
    |> TestSchema.changeset(attrs)
    |> @repo.insert()
    |> Khafra.insert(opts)
  end

  @doc "Update city"
  def update_city(city, %{} = attrs, opts) do
    city
    |> TestSchema.changeset(attrs)
    |> @repo.update()
    |> Khafra.update(opts)
  end

  @doc "Retrieve a city"
  def get_city(id) do
    @repo.get_by(TestSchema, id: id)
  end

  @doc "Find cities from search tables"
  def find_cities(search_string) do
    ManticoreQL.new()
    |> ManticoreQL.from("test_dist")
    |> ManticoreQL.match("*#{search_string}*")
    |> Giza.send()
  end
end
