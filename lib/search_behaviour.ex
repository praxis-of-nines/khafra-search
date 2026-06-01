defmodule Khafra.SearchBehaviour do
  @moduledoc """
  A behaviour for mapping Ecto schemas to Manticore Search RT tables.

  ## Column definitions

  `index_fields/0` returns a list of column definitions. Each entry can be:

    * `atom()` — field name, Manticore type auto-detected from the Ecto schema
    * `{atom(), :field | :attribute}` — explicit column role
    * `{atom(), :field | :attribute, keyword()}` — role with column-level options

  ### Roles

    * `:field` — full-text searchable (Manticore `text` column)
    * `:attribute` — stored for filtering, sorting, and grouping
      (Manticore `string`, `uint`, `bigint`, etc.)

  For non-string Ecto types (integer, float, boolean, …) the Manticore type is
  always a numeric/boolean attribute regardless of the declared role.

  ### Column options

    * `stored: true` — retain original text for retrieval (text fields only)
    * `type: :bigint` — override the auto-detected Manticore type

  ## Table options

  Optionally implement `table_options/0` to declare table-level Manticore
  settings such as `morphology`, `html_strip`, `stopwords`, etc.
  """

  @type column_role :: :field | :attribute
  @type column_opt :: {:stored, boolean()} | {:type, atom()}
  @type column_def :: atom() | {atom(), column_role()} | {atom(), column_role(), [column_opt()]}

  @doc "A list of columns to index, as bare names or rich definitions"
  @callback index_fields :: [column_def()]

  @doc "Table-level Manticore settings (morphology, stopwords, etc.)"
  @callback table_options :: keyword()

  @optional_callbacks [table_options: 0]
end
