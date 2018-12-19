defmodule Khafra.Generate.GenerateFromConfig do
  @moduledoc """
  Functions that are responsible for the logic in config from the elixir app becoming
  Sphinx config strings
  """
  alias Khafra.Generate.{TemplateSqlSource, TemplateIndex, TemplateSource, TemplateDefaultSettings}


  def gen_all() do
    all_list = [gen_default_index(),gen_searchd_settings(),gen_indexer_settings()|get_app_indexes()]

    all_templates = Enum.join(all_list, "\n\n")

    _ = File.mkdir("sphinx")

    {:ok, file} = File.open "sphinx/sphinx.conf", [:write]

    _ = IO.binwrite file, all_templates

    _ = File.close file

    all_templates
  end

  def gen_sql_source(source_name) do
    args = get_conf_by_key(source_name)

    TemplateSqlSource.get(args)
  end

  def gen_default_index() do
    gen_index(:index_defaults)
  end

  def gen_searchd_settings() do
    args = get_conf_by_key(:searchd)

    TemplateDefaultSettings.get(args)
  end

  def gen_indexer_settings() do
    args = get_conf_by_key(:indexer)

    TemplateDefaultSettings.get(args)
  end

  def gen_index(index_name) do
    args = get_conf_by_key(index_name)

    TemplateIndex.get(args)
  end

  def get_source(source_name) do
    args = get_conf_by_key(source_name)

    TemplateSource.get(args)
  end

  defp get_conf_by_key(key) do
    case Application.get_env(:khafra_search, key) do
      nil -> []
      args -> 
        [{:name, key}|args]
    end
  end

  defp get_app_indexes() do
    Enum.reverse(Enum.reduce(Application.get_env(:khafra_search, :indices, []), [], fn index, acc ->
      args = get_conf_by_key(index)

      [TemplateIndex.get(args)|acc]
    end))
  end
end