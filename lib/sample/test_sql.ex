defmodule Khafra.Sample.TestSql do
  @behaviour Khafra.SearchBehaviourSQL

  @impl Khafra.SearchBehaviourSQL
  def table_name, do: :books

  @impl Khafra.SearchBehaviourSQL
  def index_fields, do: [id: :integer, title: :string, description: :string]
end
