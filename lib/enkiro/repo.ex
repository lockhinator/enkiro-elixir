defmodule Enkiro.Repo do
  use Ecto.Repo,
    otp_app: :enkiro,
    adapter: Ecto.Adapters.Postgres
end
