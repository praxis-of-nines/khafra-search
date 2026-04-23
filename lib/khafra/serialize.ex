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
  Return a flat list of string keys that map to search values
  """
  def keys(%SQL{columns: columns}), do: columns

  def keys(%schema{} = entity) do
    entity
    |> Map.take([:id, :updated_at | schema.index_fields()])
    |> Map.keys()
  end

  @doc """
  Return a flat list of value from an entity
  """
  def values(%SQL{params: params}), do: params

  def values(%schema{} = entity) do
    entity
    |> Map.take([:id, :updated_at | schema.index_fields()])
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

  @doc """
  Return a list of search table fields derived from a database schema
  """
  def search_table_schema(%SQL{columns: columns, types: types}) do
    Enum.zip(columns, types)
    |> Enum.map(fn {col, type} -> {col, sql_to_manticore_type(type)} end)
  end

  def search_table_schema(%schema{}) do
    :fields
    |> schema.__schema__()
    |> Enum.map(fn f -> {f, ecto_to_manticore_type(schema.__schema__(:type, f))} end)
    |> Enum.filter(fn {f, _t} -> f in [:id, :updated_at | schema.index_fields()] end)
  end

  # PRIVATE FUNCTIONS
  ###################
  
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
