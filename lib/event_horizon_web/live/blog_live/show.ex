defmodule EventHorizonWeb.BlogLive.Show do
  use EventHorizonWeb, :live_view
  import EventHorizonWeb.BlogComponents

  alias EventHorizon.Blog.Article
  alias EventHorizon.Presence
  alias EventHorizon.PubSubContract
  alias EhaPubsubMessages.Analytics.{BlogVisit, BlogLike, BlogComment, BlogStatRequest}
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

      # Track this viewer by IP to dedupe multiple tabs
      user_ip = EventHorizon.ClientIP.get(socket)

      Presence.track(self(), presence_topic, socket.id, %{
        joined_at: System.system_time(:second),
        ip: user_ip
      })

      # Only publish visit if this is the first tab for this IP
      if first_visit_for_ip?(presence_topic, user_ip) do
        PubSubContract.publish!(@pubsub, BlogVisit.new!(slug: post.slug))
      else
        PubSubContract.publish!(@pubsub, BlogStatRequest.new!(slug: post.slug))
      end

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
      stats = %{
        visits: visits,
        likes: likes,
        has_liked: socket.assigns.stats.has_liked,
        comments: comments
      }

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

  @impl true
  def handle_event("like", _params, socket) do
    msg = BlogLike.new!(slug: socket.assigns.post.slug)
    PubSubContract.publish!(@pubsub, msg)

    {:noreply, assign(socket, stats: %{socket.assigns.stats | has_liked: true})}
  end

  def handle_event("send_comment", params, socket) do
    author = normalize_author(Map.get(params, "author", ""))
    content = Map.get(params, "content", "")

    socket =
      if content != "" do
        msg = BlogComment.new!(slug: socket.assigns.post.slug, author: author, content: content)
        PubSubContract.publish!(@pubsub, msg)
        push_event(socket, "reset-form", %{id: "comment-form"})
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("send_reply", params, socket) do
    author = normalize_author(Map.get(params, "author", ""))
    content = Map.get(params, "content", "")
    parent_id = Map.get(params, "parent_id")

    socket =
      if content != "" do
        msg =
          BlogComment.new!(
            slug: socket.assigns.post.slug,
            author: author,
            content: content,
            parent_id: parent_id
          )

        PubSubContract.publish!(@pubsub, msg)
        push_event(socket, "reset-form", %{id: "reply-form-#{parent_id}"})
      else
        socket
      end

    {:noreply, socket}
  end

  defp normalize_author(author) when is_binary(author) do
    case String.trim(author) do
      "" -> "Anonymous"
      trimmed -> trimmed
    end
  end

  defp normalize_author(_), do: "Anonymous"

  defp count_presence(topic) do
    Presence.list(topic)
    |> Enum.flat_map(fn {_key, %{metas: metas}} -> Enum.map(metas, & &1.ip) end)
    |> Enum.uniq()
    |> length()
  end

  defp first_visit_for_ip?(topic, ip) do
    ip_count =
      Presence.list(topic)
      |> Enum.flat_map(fn {_key, %{metas: metas}} -> Enum.map(metas, & &1.ip) end)
      |> Enum.count(&(&1 == ip))

    ip_count == 1
  end

  # A placeholder value until we get real data from remote node
  defp default_stats do
    %{visits: 1, likes: 0, has_liked: false, comments: []}
  end
end
