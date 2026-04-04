defmodule Khafra.Sample.Repo.Migrations.SampleData do
  use Ecto.Migration

  @cities ~w(Tokyo London Paris Berlin Sydney Toronto Mumbai Cairo Lagos Oslo)

  def change do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    rows =
      for city <- @cities do
        temp_lo = Enum.random(-10..15)
        temp_hi = temp_lo + Enum.random(5..20)
        score   = Float.round(:rand.uniform() * 100, 2)
        desc    = "Sample description for #{city}"

        [city: city, temp_lo: temp_lo, temp_hi: temp_hi, score: score, desc: desc,
         inserted_at: now, updated_at: now]
      end

    execute(fn -> repo().insert_all("test", rows) end, fn -> repo().delete_all("test") end)
  end
end
