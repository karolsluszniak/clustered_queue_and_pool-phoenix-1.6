defmodule Outer.Repo do
  use Ecto.Repo,
    otp_app: :outer,
    adapter: Ecto.Adapters.Postgres
end
