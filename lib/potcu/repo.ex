defmodule Potcu.Repo do
  use Ecto.Repo,
    otp_app: :potcu,
    adapter: Ecto.Adapters.Postgres
end
