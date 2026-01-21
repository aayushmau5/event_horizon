# EventHorizon Cluster Implementation

## Overview

EventHorizon tracks real-time presence locally and publishes analytics events to the cluster via PubSub. Stats updates are received from Accumulator and displayed in real-time.

---

## Implemented Components

### 1. Presence Module

**File:** `lib/event_horizon/presence.ex`

Tracks real-time viewers per blog using Phoenix.Presence.

### 2. Analytics Module

**File:** `lib/event_horizon/analytics.ex`

Publishes analytics events to the cluster:
- `track_blog_visit/1` — Publish visit event
- `track_blog_like/1` — Publish like event
- `track_blog_comment/2` — Publish comment event
- `subscribe_blog_stats/1` — Subscribe to stats updates

### 3. BlogLive.Show

**File:** `lib/event_horizon_web/live/blog_live/show.ex`

On mount (when connected):
1. Subscribes to presence changes
2. Subscribes to stats updates
3. Tracks viewer presence
4. Publishes visit event

Handles:
- `{:stats_updated, stats}` — Updates stats from Accumulator
- `presence_diff` — Updates current viewer count

---

## Architecture

```
┌─ EventHorizon ──────────────────────────────────────────────────┐
│  User visits /blog/:slug                                        │
│       │                                                         │
│       ▼                                                         │
│  BlogLive.Show.mount/3                                          │
│       │                                                         │
│       ├──► Presence.track() ──► @current_viewers                │
│       │                                                         │
│       └──► Analytics.track_blog_visit(slug)                     │
│                   │                                             │
│                   ▼                                              │
│            PubSub.broadcast("analytics:events", {:blog_visit})  │
│                   │                                             │
└───────────────────│─────────────────────────────────────────────┘
                    │ (crosses cluster via :pg)
                    ▼
┌─ Accumulator ───────────────────────────────────────────────────┐
│  Subscriber receives {:blog_visit, slug}                        │
│       │                                                         │
│       ├──► Stats.increment_blog_visit(slug)                     │
│       │                                                         │
│       └──► PubSub.broadcast("stats:blog:#{slug}", stats)        │
└───────────────────│─────────────────────────────────────────────┘
                    │ (crosses cluster via :pg)
                    ▼
┌─ EventHorizon ──────────────────────────────────────────────────┐
│  BlogLive.Show.handle_info({:stats_updated, stats})             │
│       │                                                         │
│       └──► assign(socket, :stats, stats) ──► UI updates         │
└─────────────────────────────────────────────────────────────────┘
```

---

## PubSub Topics

| Topic | Direction | Purpose |
|-------|-----------|---------|
| `"analytics:events"` | EventHorizon → Accumulator | Send visit/like/comment events |
| `"stats:blog:#{slug}"` | Accumulator → EventHorizon | Receive stats updates |
| `"presence:blog:#{slug}"` | Local (EventHorizon) | Track real-time viewers |

---

## Assigns in BlogLive.Show

| Assign | Type | Description |
|--------|------|-------------|
| `@current_viewers` | `integer` | Number of people viewing this blog |
| `@stats` | `map` | `%{visits: int, likes: int, comments: list}` |

---

## Adding Likes/Comments

To add like button functionality:

```elixir
# In BlogLive.Show
def handle_event("like", _, socket) do
  Analytics.track_blog_like(socket.assigns.post.slug)
  {:noreply, socket}
end
```

Template:
```heex
<button phx-click="like">Like ({@stats.likes})</button>
```

To add comments:

```elixir
def handle_event("add_comment", %{"content" => content}, socket) do
  comment_data = %{"content" => content, "author" => "anonymous"}
  Analytics.track_blog_comment(socket.assigns.post.slug, comment_data)
  {:noreply, socket}
end
```

---

## Important Notes

1. **Shared PubSub Name**: Both apps must use `EventHorizon.PubSub` as the PubSub name
2. **Cluster Required**: Apps must be connected via libcluster/DNSCluster
3. **Best-Effort Delivery**: PubSub events are lost if Accumulator is down (acceptable for analytics)
