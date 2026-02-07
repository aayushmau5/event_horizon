if Application.get_env(:event_horizon, :ecto_enabled, true) do
  Ecto.Adapters.SQL.Sandbox.mode(EventHorizon.Repo, :manual)
end

ExUnit.start()
