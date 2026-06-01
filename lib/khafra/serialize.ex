defmodule Khafra.Serialize do
  @moduledoc """
  Handle serialization needs of schemas and search tables.

  Much of the functionality will depend on schema having implemented Khafra.SearchBehaviour
  """

  @doc """
  A schema mapped to a search table name. If a non-schema is passed its assumed to already be
  a valid table name
  """
  def table_name(%SQL{string: string}) when is_binary(string) do
    case Regex.run(~r/\bfrom\s+(\w+)/i, string) do
      [_, table] -> String.downcase(table)
      _ -> nil
    end
  end

  def table_name(%schema{}) do
    schema
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
    |> String.downcase()
    |> String.trim_trailing("schema")
  end

  def table_name(schema) when is_atom(schema), do: table_name(struct(schema))

  def table_name(table_name), do: table_name

  @doc """
  Return a flat list of string keys that map to search values. Accepts a full SQL
  query; a row result (ecto schema struct) or a keyword list row return from SQL
  """
  def keys(%SQL{columns: columns}), do: columns

  def keys(%schema{} = entity) do
    entity
    |> Map.take([:id, :updated_at | field_names(schema.index_fields())])
    |> Map.keys()
  end

  def keys(row) when is_list(row), do: Keyword.keys(row)

  @doc """
  Return a flat list of value from an entity
  """
  def values(%SQL{params: params}), do: params

  def values(%schema{} = entity) do
    entity
    |> Map.take([:id, :updated_at | field_names(schema.index_fields())])
    |> Enum.map(fn 
         {_, %DateTime{} = val} ->
           DateTime.to_unix(val, :microsecond)
        {_, %NaiveDateTime{} = val} ->
           val
           |> DateTime.from_naive!("Etc/UTC")
           |> DateTime.to_unix(:microsecond)
         {_, val} ->
           val
       end)
  end

  def values(row) when is_list(row), do: Keyword.values(row)

  @doc """
  Return a list of search table fields derived from a database schema
  """
  def search_table_schema(%SQL{columns: columns, types: types}) do
    Enum.zip(columns, types)
    |> Enum.map(fn {col, type} -> {col, sql_to_manticore_type(type)} end)
  end

  def search_table_schema(%schema{}) do
    index_defs = schema.index_fields()
    names = field_names(index_defs)
    defs_map = column_defs_map(index_defs)

    :fields
    |> schema.__schema__()
    |> Enum.map(fn f ->
      {f, resolve_manticore_type(f, schema.__schema__(:type, f), defs_map)}
    end)
    |> Enum.filter(fn {f, _t} -> f in [:id, :updated_at | names] end)
  end

  @doc """
  Extract bare field names from a list of column definitions.
  Normalizes `atom | {atom, role} | {atom, role, opts}` → `atom`.
  """
  def field_names(index_defs) do
    Enum.map(index_defs, &field_name/1)
  end

  @doc "Extract the bare field name from a column definition."
  def field_name(name) when is_atom(name), do: name
  def field_name({name, _role}), do: name
  def field_name({name, _role, _opts}), do: name

  # PRIVATE FUNCTIONS
  ###################

  # Build a map of field_name => {role, opts} for rich defs; bare atoms get nil.
  defp column_defs_map(index_defs) do
    Map.new(index_defs, fn
      name when is_atom(name)    -> {name, nil}
      {name, role}               -> {name, {role, []}}
      {name, role, opts}         -> {name, {role, opts}}
    end)
  end

  # Resolve the Manticore column type for a field, respecting explicit role/type overrides.
  defp resolve_manticore_type(field, ecto_type, defs_map) do
    case Map.get(defs_map, field) do
      # Bare atom or field not in defs — auto-detect
      nil ->
        ecto_to_manticore_type(ecto_type)

      {role, opts} ->
        case Keyword.get(opts, :type) do
          # Explicit type override
          manticore_type when not is_nil(manticore_type) ->
            maybe_stored(manticore_type, opts)

          # No override — derive from role + ecto type
          nil ->
            auto = ecto_to_manticore_type(ecto_type)
            apply_role(auto, role, opts)
        end
    end
  end

  # When the auto-detected type is :text, the role controls whether it stays
  # :text (full-text field) or becomes :string (stored attribute).
  defp apply_role(:text, :attribute, _opts), do: :string
  defp apply_role(:text, :field, opts), do: maybe_stored(:text, opts)
  defp apply_role(type, _role, _opts), do: type

  # Append " stored" to text columns that opt into it.
  defp maybe_stored(:text, opts) do
    if Keyword.get(opts, :stored, false), do: :"text stored", else: :text
  end

  defp maybe_stored(type, _opts), do: type

  # Primary keys
  defp ecto_to_manticore_type(:id),             do: :uint
  defp ecto_to_manticore_type(:binary_id),      do: :string
  # Numeric
  defp ecto_to_manticore_type(:integer),        do: :bigint
  defp ecto_to_manticore_type(:float),          do: :float
  defp ecto_to_manticore_type(:decimal),        do: :float
  # Text
  defp ecto_to_manticore_type(:string),         do: :text
  defp ecto_to_manticore_type(:binary),         do: :string
  # Boolean
  defp ecto_to_manticore_type(:boolean),        do: :bool
  # Date / time — values are serialized as microsecond unix timestamps (bigint)
  defp ecto_to_manticore_type(:utc_datetime),      do: :bigint
  defp ecto_to_manticore_type(:utc_datetime_usec), do: :bigint
  defp ecto_to_manticore_type(:naive_datetime),    do: :bigint
  defp ecto_to_manticore_type(:naive_datetime_usec), do: :bigint
  defp ecto_to_manticore_type(:date),           do: :uint
  defp ecto_to_manticore_type(:time),           do: :bigint
  defp ecto_to_manticore_type(:time_usec),      do: :bigint
  # Structured
  defp ecto_to_manticore_type(:map),            do: :json
  defp ecto_to_manticore_type(:any),            do: :json
  defp ecto_to_manticore_type({:array, :integer}), do: :multi64
  defp ecto_to_manticore_type({:array, _}),     do: :json
  # Fallback
  defp ecto_to_manticore_type(_),               do: :string

  # SQL type mappings
  defp sql_to_manticore_type(:int2),            do: :bigint
  defp sql_to_manticore_type(:int4),            do: :bigint
  defp sql_to_manticore_type(:int8),            do: :bigint
  defp sql_to_manticore_type(:integer),         do: :bigint
  defp sql_to_manticore_type(:bigint),          do: :bigint
  defp sql_to_manticore_type(:float4),          do: :float
  defp sql_to_manticore_type(:float8),          do: :float
  defp sql_to_manticore_type(:numeric),         do: :float
  defp sql_to_manticore_type(:bool),            do: :bool
  defp sql_to_manticore_type(:boolean),         do: :bool
  defp sql_to_manticore_type(:text),            do: :text
  defp sql_to_manticore_type(:varchar),         do: :text
  defp sql_to_manticore_type(:json),            do: :json
  defp sql_to_manticore_type(:jsonb),           do: :json
  defp sql_to_manticore_type(:timestamp),       do: :bigint
  defp sql_to_manticore_type(:timestamptz),     do: :bigint
  defp sql_to_manticore_type(:date),            do: :uint
  defp sql_to_manticore_type(_),                do: :string
end
