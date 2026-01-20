defmodule EventHorizon.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EventHorizonWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:event_horizon, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EventHorizon.PubSub},

      # Cluster management
      {Task.Supervisor, name: EventHorizon.TaskSupervisor},
      EventHorizon.Cluster.Outbox,
      EventHorizon.Cluster.Monitor,

      EventHorizonWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EventHorizon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EventHorizonWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
