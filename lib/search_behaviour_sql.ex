defmodule Khafra.SearchBehaviourSQL do
  @moduledoc """
  A behaviour implemented to allow automatic inserts after database updates to
  real time search tables.

  This version supports ~SQL library
  """

  @doc "tables name in atom form"
  @callback table_name :: atom()

  @doc "A list of fields to index"
  @callback index_fields :: Keyword.t()
end
