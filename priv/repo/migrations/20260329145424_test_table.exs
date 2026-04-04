defmodule Khafra.Sample.Repo.Migrations.TestTable do
  use Ecto.Migration

  def change do
    create table("test") do
      add :city,    :string
      add :temp_lo, :integer
      add :temp_hi, :integer
      add :score,   :float
      add :desc,    :string

      timestamps()
    end
  end
end
