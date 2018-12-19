defmodule Khafra.Generate.Template do
  @moduledoc """
  Helper functions useful for generating template strings
  """
  def non_unique_arg(map, list_key, key, arg) do
    case Map.has_key?(map, list_key) do
      true  -> Map.replace!(map, list_key, [line_item(key, arg)|map[list_key]])
      false -> Map.put(map, list_key, [line_item(key, arg)])
    end
  end

  def combine_non_unique_args(list_args), do: Enum.join(list_args, "\n  ")

  def line_item(key, arg), do: "#{key} = #{arg}"

  def optional_args(map, [], []), do: map

  def optional_args(map, [optional_arg|optional_args], [default_arg|default_args]) do
    case Map.has_key?(map, optional_arg) do
      true  -> optional_args(map, optional_args, default_args)
      false -> optional_args(Map.put(map, optional_arg, default_arg), optional_args, default_args)
    end
  end
end