defmodule Khafra.Sample.Repo do
  use Ecto.Repo,
    otp_app: :khafra_search,
    adapter: Ecto.Adapters.Postgres
end
