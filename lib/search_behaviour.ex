defmodule Khafra.SearchBehaviour do
  @moduledoc """
  A behaviour implemented to allow automatic inserts after database updates to
  real time search tables.
  """

  @doc "A list of fields to index"
  @callback index_fields :: list(atom())
end
