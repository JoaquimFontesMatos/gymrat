defmodule Gymrat.Repo do
  use Ecto.Repo,
    otp_app: :gymrat,
    adapter: Ecto.Adapters.Postgres
end
