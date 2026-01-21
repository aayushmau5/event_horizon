defmodule EventHorizonWeb.SiteStatsLive do
  @moduledoc """
  Embedded LiveView that displays site-wide stats in the footer.

  Handles its own presence tracking and PubSub subscriptions.
  Use with `live_render/3` in the footer.
  """

  use EventHorizonWeb, :live_view

  alias EventHorizon.Presence

  @presence_topic "presence:site"

  @impl true
  def mount(_params, _session, socket) do
    socket = setup_analytics(socket)
    {:ok, socket, layout: false}
  end

  defp setup_analytics(socket) do
    if connected?(socket) do
      # Subscribe to presence changes
      Phoenix.PubSub.subscribe(EventHorizon.PubSub, @presence_topic)
      # Subscribe to stats update received from remote node
      Phoenix.PubSub.subscribe(EventHorizon.PubSub, "stats: site")

      Presence.track(self(), @presence_topic, socket.id, %{
        joined_at: System.system_time(:second)
      })

      # Publish visit event to remote node
      Phoenix.PubSub.broadcast(EventHorizon.PubSub, "analytics:events", {:site_visit})

      assign(socket, online_count: count_presence(), total_visits: 0)
    else
      assign(socket, online_count: 1, total_visits: 0)
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
    """
  end

  # Handle stats updates from remote node
  @impl true
  def handle_info({:site_stats_updated, stats}, socket) do
    {:noreply, assign(socket, :total_visits, stats.visits)}
  end

  # Handle presence changes
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :online_count, count_presence())}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp count_presence do
    # Since, this is an embedded liveview, with id being "site-stats" provided in live_render
    # All the presence data gets clubbed into one "site-stats" key
    presence = Presence.list(@presence_topic)
    presences = Map.get(presence, "site-stats", %{metas: []})
    length(presences.metas)
  end
end
