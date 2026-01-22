defmodule EventHorizonWeb.BlogLive.Show do
  use EventHorizonWeb, :live_view

  alias EventHorizon.Blog.Article
  alias EventHorizon.Presence
  alias EventHorizon.PubSubContract
  alias EhaPubsubMessages.Analytics.BlogVisit
  alias EhaPubsubMessages.Stats.BlogUpdated
  alias EhaPubsubMessages.Presence.{BlogPresence, PresenceRequest}
  alias EhaPubsubMessages.Topics

  @pubsub EventHorizon.PubSub

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
      blog_stats_topic = Topics.blog_stats(slug: post.slug)

      # Subscribe to presence changes
      Phoenix.PubSub.subscribe(@pubsub, presence_topic)

      # Subscribe to blog-specific stats updates (dynamic topic)
      Phoenix.PubSub.subscribe(@pubsub, blog_stats_topic)

      # Subscribe to presence requests from remote
      PubSubContract.subscribe!(@pubsub, PresenceRequest)

      # Track this viewer
      Presence.track(self(), presence_topic, socket.id, %{
        joined_at: System.system_time(:second)
      })

      # Publish visit event to remote node using contract
      PubSubContract.publish!(@pubsub, BlogVisit.new!(slug: post.slug))

      current_viewers = count_presence(presence_topic)
      assign(socket, current_viewers: current_viewers, stats: default_stats())
    else
      assign(socket, current_viewers: 0, stats: default_stats())
    end
  end

  # Handle stats updates from remote node (contract message)
  @impl true
  def handle_info(
        %BlogUpdated{slug: slug, visits: visits, likes: likes, comments: comments},
        socket
      ) do
    if slug == socket.assigns.post.slug do
      stats = %{visits: visits, likes: likes, comments: comments}
      {:noreply, assign(socket, :stats, stats)}
    else
      {:noreply, socket}
    end
  end

  # Handle presence changes
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    presence_topic = "presence:blog:#{socket.assigns.post.slug}"
    current_viewers = count_presence(presence_topic)
    {:noreply, assign(socket, :current_viewers, current_viewers)}
  end

  # Handle remote presence request - respond with current count for this blog (contract message)
  def handle_info(%PresenceRequest{type: :blog}, socket) do
    slug = socket.assigns.post.slug
    count = count_presence("presence:blog:#{slug}")
    msg = BlogPresence.new!(slug: slug, count: count)
    PubSubContract.publish!(@pubsub, msg)
    {:noreply, socket}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp count_presence(topic) do
    Presence.list(topic) |> map_size()
  end

  # A placeholder value until we get real data from remote node
  defp default_stats do
    %{visits: 1, likes: 0, comments: []}
  end
end
