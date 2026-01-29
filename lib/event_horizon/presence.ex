defmodule EventHorizon.Presence do
  @moduledoc """
  Tracks real-time presence for site and blog visitors.

  Uses Phoenix.Presence with PG2 adapter for cluster-wide presence tracking.
  Broadcasts presence counts to Accumulator using contract messages.

  Presence is tracked by user IP to deduplicate multiple tabs from the same user.
  """

  use Phoenix.Presence,
    otp_app: :event_horizon,
    pubsub_server: EventHorizon.PubSub

  alias EventHorizon.PubSubContract
  alias EhaPubsubMessages.Presence.{SitePresence, BlogPresence}

  @pubsub EventHorizon.PubSub

  def init(_opts), do: {:ok, %{}}

  def handle_metas("presence:site", _metas, presences, state) do
    count = count_unique_ips(presences)
    msg = SitePresence.new!(count: count)
    PubSubContract.publish!(@pubsub, msg)
    {:ok, state}
  end

  def handle_metas("presence:blog:" <> slug, _metas, presences, state) do
    count = count_unique_ips(presences)
    msg = BlogPresence.new!(slug: slug, count: count)
    PubSubContract.publish!(@pubsub, msg)
    {:ok, state}
  end

  def handle_metas(_topic, _metas, _presences, state) do
    {:ok, state}
  end

  defp count_unique_ips(presences) do
    presences
    |> Enum.flat_map(fn {_key, metas} -> Enum.map(metas, & &1.ip) end)
    |> Enum.uniq()
    |> length()
  end
end
