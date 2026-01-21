defmodule EventHorizonWeb.BlogLive.Show do
  use EventHorizonWeb, :live_view

  alias EventHorizon.Blog.Article
  alias EventHorizon.Presence

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case EventHorizon.Blog.get_blog(String.downcase(slug)) do
      nil ->
        {:ok, push_navigate(socket, to: "/not-found")}

      post ->
        socket = setup_analytics(socket, post)
        adjacent_posts = EventHorizon.Blog.get_adjacent_articles(post.slug)

        {:ok,
         socket
         |> assign(post: post, adjacent_posts: adjacent_posts)
         |> SEO.assign(post)}
    end
  end

  defp setup_analytics(socket, post) do
    if connected?(socket) do
      presence_topic = "presence:blog:#{post.slug}"

      # Subscribe to presence changes and stats updates
      Phoenix.PubSub.subscribe(EventHorizon.PubSub, presence_topic)
      # Subscribes to stats update received from remote node
      Phoenix.PubSub.subscribe(EventHorizon.PubSub, "stats:blog:#{post.slug}")

      # Track this viewer
      Presence.track(self(), presence_topic, socket.id, %{
        joined_at: System.system_time(:second)
      })

      # Publish visit event to remote node
      Phoenix.PubSub.broadcast(EventHorizon.PubSub, "analytics:events", {:blog_visit, post.slug})

      current_viewers = count_presence(presence_topic)
      assign(socket, current_viewers: current_viewers, stats: default_stats())
    else
      assign(socket, current_viewers: 0, stats: default_stats())
    end
  end

  # Handle stats updates from remote node
  @impl true
  def handle_info({:stats_updated, stats}, socket) do
    {:noreply, assign(socket, :stats, stats)}
  end

  # Handle presence changes
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    presence_topic = "presence:blog:#{socket.assigns.post.slug}"
    current_viewers = count_presence(presence_topic)
    {:noreply, assign(socket, :current_viewers, current_viewers)}
  end

  defp count_presence(topic) do
    Presence.list(topic) |> map_size()
  end

  # A placeholder value until we get real data from remote node
  defp default_stats do
    %{visits: 1, likes: 0, comments: []}
  end
end
