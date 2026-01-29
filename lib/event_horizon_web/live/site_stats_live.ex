defmodule EventHorizonWeb.SiteStatsLive do
  @moduledoc """
  Embedded LiveView that displays site-wide stats in the footer.

  Handles its own presence tracking and PubSub subscriptions.
  Use with `live_render/3` in the footer.
  """

  use EventHorizonWeb, :live_view

  import EventHorizonWeb.Components.SpotifyNowPlaying

  alias EventHorizon.Presence
  alias EventHorizon.PubSubContract
  alias EhaPubsubMessages.Analytics.{SiteVisit, SiteStatRequest}
  alias EhaPubsubMessages.Stats.SiteUpdated
  alias EhaPubsubMessages.Stats.Spotify.NowPlaying
  alias EhaPubsubMessages.Presence.{SitePresence, PresenceRequest}

  @pubsub EventHorizon.PubSub
  @presence_topic "presence:site"

  @impl true
  def mount(_params, _session, socket) do
    socket = setup_analytics(socket)
    {:ok, socket, layout: false}
  end

  defp setup_analytics(socket) do
    if connected?(socket) do
      # Subscribe to presence changes
      Phoenix.PubSub.subscribe(@pubsub, @presence_topic)

      # Subscribe to messages we receive per contract
      PubSubContract.subscribe_all(@pubsub)

      user_ip = EventHorizon.ClientIP.get(socket)

      Presence.track(self(), @presence_topic, socket.id, %{
        joined_at: System.system_time(:second),
        ip: user_ip
      })

      # Only publish visit if this is the first tab for this IP
      if first_visit_for_ip?(@presence_topic, user_ip) do
        PubSubContract.publish!(@pubsub, SiteVisit.new!(%{}))
      else
        PubSubContract.publish!(@pubsub, SiteStatRequest.new!(%{}))
      end

      assign(socket, online_count: count_presence(), total_visits: 0, now_playing: nil)
    else
      assign(socket, online_count: 1, total_visits: 0, now_playing: nil)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="site-stats">
      <span class="site-stats-item">
        <span class="online-dot"></span>
        {@online_count} online
      </span>
      <span class="site-stats-separator">·</span>
      <span class="site-stats-item">{@total_visits} visits</span>
    </div>
    <.spotify_now_playing now_playing={@now_playing} />
    """
  end

  # Handle stats updates from remote node (contract message)
  @impl true
  def handle_info(%SiteUpdated{visits: visits}, socket) do
    {:noreply, assign(socket, total_visits: visits)}
  end

  def handle_info(%NowPlaying{data: nil}, socket) do
    {:noreply, assign(socket, now_playing: nil)}
  end

  def handle_info(%NowPlaying{data: data}, socket) do
    {:noreply, assign(socket, now_playing: data)}
  end

  # Handle presence changes
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, online_count: count_presence())}
  end

  # Handle remote presence request - respond with current count (contract message)
  def handle_info(%PresenceRequest{type: :site}, socket) do
    count = count_presence()
    PubSubContract.publish!(@pubsub, SitePresence.new!(count: count))
    {:noreply, socket}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp count_presence do
    Presence.list(@presence_topic)
    |> Enum.flat_map(fn {_key, %{metas: metas}} -> Enum.map(metas, & &1.ip) end)
    |> Enum.uniq()
    |> length()
  end

  defp first_visit_for_ip?(topic, ip) do
    ip_count =
      Presence.list(topic)
      |> Enum.flat_map(fn {_key, %{metas: metas}} -> Enum.map(metas, & &1.ip) end)
      |> Enum.count(&(&1 == ip))

    # <= 1 because Presence.track is async and may not be reflected yet
    ip_count <= 1
  end
end
