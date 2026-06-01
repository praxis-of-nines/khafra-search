defmodule Khafra.Sample.TestSchema do
  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Khafra.SearchBehaviour

  schema "test" do
    field :city, :string
    field :temp_lo, :integer
    field :temp_hi, :integer
    field :score, :float
    field :desc, :string

    timestamps()
  end

  @doc false
  def changeset(test, attrs) do
    test
    |> cast(attrs, [:city, :temp_lo, :temp_hi, :score, :desc])
  end

  @impl Khafra.SearchBehaviour
  def index_fields do
    [
      {:city, :field, stored: true},
      {:desc, :field},
      {:temp_lo, :attribute},
      {:temp_hi, :attribute},
      {:score, :attribute}
    ]
  end
end
