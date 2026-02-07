defmodule EventHorizon.Repo do
  use Ecto.Repo,
    otp_app: :event_horizon,
    adapter: Ecto.Adapters.Postgres
end
