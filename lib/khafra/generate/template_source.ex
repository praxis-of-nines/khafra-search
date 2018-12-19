defmodule Khafra.Generate.TemplateSource do
  import Khafra.Generate.Template

  def get(args), do: get(args, %{})
  
  def get([{:name, name}|args], map), do: get(args, Map.put(map, :name, name))
  
  def get([{:attributes, attribute_list}|args], map) do
    attr_str = combine_non_unique_args(Enum.reduce(attribute_list, [], fn {field, type}, acc ->
      [line_item(to_sphinx_source_attr(type), field)|acc]
    end))

    get(args, Map.put(map, :attributes, attr_str))
  end

  def get([{:fields, field_list}|args], map) do
    attr_str = combine_non_unique_args(Enum.reduce(field_list, [], fn {field, type}, acc ->
      [line_item(to_sphinx_source_field(type), field)|acc]
    end))
    
    get(args, Map.put(map, :fields, attr_str))
  end

  def get([{:parent, parent_name}|args], map) do
    # Name guaranteed to be first, therefore safe:
    name = map.name

    get(args, Map.put(map, :index_name, "#{name} : #{parent_name}"))
  end

  def get([{:query, arg}|args], map) do
    get(args, non_unique_arg(map, :args, :sql_query, arg))
  end

  def get([{key, arg}|args], map) when is_atom(arg) or is_binary(arg), do: get(args, non_unique_arg(map, :args, key, arg))

  def get([], %{:args => arg_list} = map) when is_list(arg_list) do
    get([], Map.replace!(map, :args, combine_non_unique_args(arg_list)))
  end

  def get([], %{:name => name, :args => args, :attributes => attributes, :fields => fields} = map) do
    index_name = case map do
      %{index_name: index_name} -> index_name
      _ -> name
    end

    ~s"""
    source #{index_name}
    {
      #{args}

      #{attributes}

      #{fields}
    }
    """
  end

  def get([], map) do
    get([], optional_args(map, [:attributes, :fields], ["## No Attributes", "## No Fields"]))
  end

  defp to_sphinx_source_attr(:string), do: "sql_attr_string"
  defp to_sphinx_source_attr(:integer), do: "sql_attr_uint"
  defp to_sphinx_source_attr(:timestamp), do: "sql_attr_timestamp"
  defp to_sphinx_source_attr(:datetime), do: "sql_attr_timestamp"

  defp to_sphinx_source_field(:string), do: "sql_field_string"
  defp to_sphinx_source_field(:integer), do: "sql_field_uint"
  defp to_sphinx_source_field(:timestamp), do: "sql_field_timestamp"
  defp to_sphinx_source_field(:datetime), do: "sql_field_timestamp"
end