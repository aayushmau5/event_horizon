# Plan: App-1 (EventHorizon) — Blog Host

## Overview

EventHorizon tracks user presence locally, sends events to Accumulator via RPC, and broadcasts updates to all connected LiveViews.

---

## 1. Fix Existing Bug

**File:** `lib/event_horizon/cluster/outbox.ex:113`

- Change `:sync_comlete` → `:sync_complete`

---

## 2. Add Phoenix.Presence for Real-Time Viewer Tracking

### 2.1 Create Presence Module

**File:** `lib/event_horizon/presence.ex`

```elixir
defmodule EventHorizon.Presence do
  use Phoenix.Presence,
    otp_app: :event_horizon,
    pubsub_server: EventHorizon.PubSub
end
```

### 2.2 Add to Supervision Tree

**File:** `lib/event_horizon/application.ex`

Add `EventHorizon.Presence` to children list.

---

## 3. Define PubSub Topics

| Topic                    | Purpose                          |
| ------------------------ | -------------------------------- |
| `"presence:site"`        | Track all site visitors          |
| `"presence:blog:#{slug}"` | Track viewers per blog           |
| `"stats:site"`           | Broadcast site-wide stats updates |
| `"stats:blog:#{slug}"`   | Broadcast per-blog stats updates |

---

## 4. Update Cluster Module

**File:** `lib/event_horizon/cluster.ex`

### 4.1 Modify Functions to Return New Count

```elixir
def increment_visit(page_id) do
  case execute_or_buffer(:increment_visit, %{page_id: page_id}) do
    {:ok, count} when is_integer(count) -> {:ok, count}
    {:ok, :buffered} -> {:ok, :buffered}
    error -> error
  end
end

def increment_blog_visit(slug) do
  execute_or_buffer(:increment_blog_visit, %{slug: slug})
end

def get_blog_stats(slug) do
  # Sync call to get current stats (visits, likes, comments)
  execute_sync(:get_blog_stats, %{slug: slug})
end

def get_site_stats() do
  execute_sync(:get_site_stats, %{})
end
```

### 4.2 Add Sync Execution (for reads)

```elixir
defp execute_sync(function, payload) do
  case Monitor.remote_node() do
    nil -> {:error, :disconnected}
    node -> :erpc.call(node, Accumulator.Remote.Handler, function, [payload], @rpc_timeout)
  end
rescue
  e in ErlangError -> {:error, e.original}
end
```

---

## 5. Update BlogLive.Show

**File:** `lib/event_horizon_web/live/blog_live/show.ex`

```elixir
defmodule EventHorizonWeb.BlogLive.Show do
  use EventHorizonWeb, :live_view

  alias EventHorizon.{Blog.Article, Cluster, Presence}

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case EventHorizon.Blog.get_blog(String.downcase(slug)) do
      nil ->
        {:ok, push_navigate(socket, to: "/not-found")}

      post ->
        if connected?(socket) do
          # Subscribe to stats updates for this blog
          Phoenix.PubSub.subscribe(EventHorizon.PubSub, "stats:blog:#{post.slug}")

          # Track presence
          Presence.track(self(), "presence:blog:#{post.slug}", socket.id, %{
            joined_at: System.system_time(:second)
          })

          # Increment visit and broadcast
          handle_visit(post.slug)
        end

        stats = fetch_stats(post.slug)
        adjacent_posts = EventHorizon.Blog.get_adjacent_articles(post.slug)
        current_viewers = count_presence("presence:blog:#{post.slug}")

        {:ok,
         socket
         |> assign(post: post, adjacent_posts: adjacent_posts)
         |> assign(stats: stats, current_viewers: current_viewers)
         |> SEO.assign(post)}
    end
  end

  # Handle stats broadcast
  @impl true
  def handle_info({:stats_updated, stats}, socket) do
    {:noreply, assign(socket, :stats, stats)}
  end

  # Handle presence diff
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    current_viewers = count_presence("presence:blog:#{socket.assigns.post.slug}")
    {:noreply, assign(socket, :current_viewers, current_viewers)}
  end

  defp handle_visit(slug) do
    case Cluster.increment_blog_visit(slug) do
      {:ok, stats} when is_map(stats) ->
        Phoenix.PubSub.broadcast(
          EventHorizon.PubSub,
          "stats:blog:#{slug}",
          {:stats_updated, stats}
        )
      _ -> :ok
    end
  end

  defp fetch_stats(slug) do
    case Cluster.get_blog_stats(slug) do
      {:ok, stats} -> stats
      _ -> %{visits: 0, likes: 0, comments: []}
    end
  end

  defp count_presence(topic) do
    Presence.list(topic) |> map_size()
  end
end
```

---

## 6. Update HomeLive.Index (Site-Wide Stats)

**File:** `lib/event_horizon_web/live/home_live/index.ex`

Similar pattern:

- Subscribe to `"stats:site"` and `"presence:site"`
- Track presence on mount
- Call `Cluster.increment_visit("home")`
- Broadcast site stats updates

---

## 7. Add Like/Comment Handlers in BlogLive.Show

```elixir
def handle_event("like", _, socket) do
  slug = socket.assigns.post.slug

  case Cluster.update_likes(slug) do
    {:ok, stats} ->
      Phoenix.PubSub.broadcast(EventHorizon.PubSub, "stats:blog:#{slug}", {:stats_updated, stats})
      {:noreply, socket}
    _ ->
      {:noreply, socket}
  end
end

def handle_event("add_comment", %{"content" => content}, socket) do
  slug = socket.assigns.post.slug
  comment_data = %{content: content, author: "anonymous", inserted_at: DateTime.utc_now()}

  case Cluster.add_comment(slug, comment_data) do
    {:ok, stats} ->
      Phoenix.PubSub.broadcast(EventHorizon.PubSub, "stats:blog:#{slug}", {:stats_updated, stats})
      {:noreply, socket}
    _ ->
      {:noreply, socket}
  end
end
```

---

## Summary: App-1 Responsibilities

| Component   | Responsibility                     |
| ----------- | ---------------------------------- |
| `Presence`  | Track real-time viewers locally    |
| `Cluster`   | RPC to app-2, buffer on disconnect |
| `PubSub`    | Broadcast stats to all LiveViews   |
| `LiveViews` | Subscribe, display, trigger events |

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         App-1 (EventHorizon)                    │
├─────────────────────────────────────────────────────────────────┤
│  User visits blog                                               │
│       │                                                         │
│       ▼                                                         │
│  BlogLive.Show                                                  │
│       │                                                         │
│       ├──► Presence.track() ──► Local presence state            │
│       │                                                         │
│       └──► Cluster.increment_blog_visit(slug)                   │
│                   │                                             │
│                   ▼                                             │
│            ┌──────────────┐                                     │
│            │ Connected?   │                                     │
│            └──────┬───────┘                                     │
│              Yes  │  No                                         │
│                   │   └──► Outbox.enqueue() ──► ETS buffer      │
│                   ▼                                             │
│            :erpc.call() ─────────────────────────────────┐      │
│                                                          │      │
│       ◄── {:ok, stats} ◄─────────────────────────────────┤      │
│       │                                                  │      │
│       ▼                                                  │      │
│  PubSub.broadcast("stats:blog:#{slug}", stats)           │      │
│       │                                                  │      │
│       ▼                                                  │      │
│  All LiveViews subscribed ──► handle_info ──► UI update  │      │
└──────────────────────────────────────────────────────────│──────┘
                                                           │
                                                           ▼
                                              App-2 (Accumulator)
```
