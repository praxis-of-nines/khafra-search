defmodule Khafra.Generate.TemplateSqlSource do
  import Khafra.Generate.Template

  def get(args), do: get(args, %{})
  
  def get([{:name, name}|args], map), do: get(args, Map.put(map, :name, name))
  def get([{:adapter, :postgres}|args], map), do: get(args, Map.put(map, :type, "pgsql"))
  def get([{:adapter, :mysql}|args], map), do: get(args, Map.put(map, :type, "mysql"))

  def get([{:hostname, arg}|args], map), do: get(args, non_unique_arg(map, :conn, "sql_host", arg))
  def get([{:username, arg}|args], map), do: get(args, non_unique_arg(map, :conn, "sql_user", arg))
  def get([{:password, arg}|args], map), do: get(args, non_unique_arg(map, :conn, "sql_pass", arg))
  def get([{:database, arg}|args], map), do: get(args, non_unique_arg(map, :conn, "sql_db", arg))

  def get([], %{:conn => conn_list} = map) when is_list(conn_list) do
    get([], Map.replace!(map, :conn, combine_non_unique_args(conn_list)))
  end

  def get([], %{:name => name, :type => type, :conn => connection_settings}) do
    ~s"""
    source #{name}
    {
      type = #{type}

      #{connection_settings}
    }
    """
  end
end