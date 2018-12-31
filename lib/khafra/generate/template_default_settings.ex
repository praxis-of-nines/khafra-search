defmodule Khafra.Generate.TemplateDefaultSettings do
  import Khafra.Generate.Template

  def get(args), do: get(args, %{})
  
  def get([{:name, name}|args], map), do: get(args, Map.put(map, :name, name))

  def get([{key, arg}|args], map) when key in [:listen_mysql, :listen_sphinx, :listen_http] do
    get(args, non_unique_arg(map, :args, "listen", arg))
  end

  def get([{key, arg}|args], map) do
    arg = String.replace(arg, "[cwd!]", System.cwd())

    get(args, non_unique_arg(map, :args, key, arg))
  end

  def get([], %{:args => arg_list} = map) when is_list(arg_list) do
    get([], Map.replace!(map, :args, combine_non_unique_args(arg_list)))
  end

  def get([], %{:name => name, :args => args}) do
    name_upper = String.upcase(Atom.to_string(name))

    ~s"""
    ## #{name_upper}
    ####################################################
    #{name}
    {
      #{args}
    }
    """
  end
end