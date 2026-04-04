defmodule Khafra.Serialize do
  @moduledoc """
  Handle serialization needs of schemas and search tables.

  Much of the functionality will depend on schema having implemented Khafra.SearchBehaviour
  """

  @doc """
  A schema mapped to a search table name. If a non-schema is passed its assumed to already be
  a valid table name
  """
  def table_name(%schema{}) do
    schema
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
    |> String.downcase()
  end

  def table_name(table_name), do: table_name

  @doc """
  Return a flat list of string keys that map to search values
  """
  def keys(%schema{} = entity) do
    entity
    |> Map.take([:id, :updated_at | schema.index_fields()])
    |> Map.keys()
  end

  @doc """
  Return a flat list of value from an entity
  """
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
end
