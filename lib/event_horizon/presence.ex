defmodule EventHorizon.Presence do
  @moduledoc """
  Tracks real-time presence for site and blog visitors.

  Uses Phoenix.Presence with PG2 adapter for cluster-wide presence tracking.
  Broadcasts presence counts to "stats:presence" topic for Accumulator consumption.
  """

  use Phoenix.Presence,
    otp_app: :event_horizon,
    pubsub_server: EventHorizon.PubSub

  @pubsub EventHorizon.PubSub
  @presence_topic "stats:presence"

  def init(_opts), do: {:ok, %{}}

  def handle_metas("presence:site", _metas, presences, state) do
    count = Map.get(presences, "site-stats", []) |> length()
    Phoenix.PubSub.broadcast(@pubsub, @presence_topic, {:site_presence, count})
    {:ok, state}
  end

  def handle_metas("presence:blog:" <> slug, _metas, presences, state) do
    count = map_size(presences)
    Phoenix.PubSub.broadcast(@pubsub, @presence_topic, {:blog_presence, slug, count})
    {:ok, state}
  end

  def handle_metas(_topic, _metas, _presences, state) do
    {:ok, state}
  end
end
