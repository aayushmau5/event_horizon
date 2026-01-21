# Accumulator Implementation Guide

## Overview

Accumulator subscribes to analytics events from EventHorizon via PubSub, processes them, and broadcasts updated stats back to the cluster.

---

## Architecture

```
EventHorizon                          Accumulator
     │                                     │
     │  PubSub: "analytics:events"         │
     │ ──────────────────────────────────► │
     │     {:blog_visit, slug}             │
     │     {:blog_like, slug}              │
     │     {:blog_comment, slug, data}     │
     │                                     │
     │                                ┌────┴────┐
     │                                │ Process │
     │                                │  Event  │
     │                                └────┬────┘
     │                                     │
     │  PubSub: "stats:blog:#{slug}"       │
     │ ◄────────────────────────────────── │
     │     {:stats_updated, stats}         │
     │                                     │
```

---

## 1. Shared PubSub Setup

**Critical:** Both apps must use the same PubSub name for cross-cluster messaging.

**File:** `lib/accumulator/application.ex`

```elixir
children = [
  # Use the same name as EventHorizon
  {Phoenix.PubSub, name: EventHorizon.PubSub, adapter: Phoenix.PubSub.PG2},
  # ... other children
  Accumulator.Analytics.Subscriber
]
```

---

## 2. Analytics Subscriber

**File:** `lib/accumulator/analytics/subscriber.ex`

```elixir
defmodule Accumulator.Analytics.Subscriber do
  @moduledoc """
  Subscribes to analytics events from EventHorizon and processes them.

  Listens on "analytics:events" topic and broadcasts stats updates back.
  """

  use GenServer
  require Logger

  @pubsub EventHorizon.PubSub
  @analytics_topic "analytics:events"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    Phoenix.PubSub.subscribe(@pubsub, @analytics_topic)
    Logger.info("Analytics subscriber started, listening on #{@analytics_topic}")
    {:ok, %{}}
  end

  @impl true
  def handle_info({:site_visit}, state) do
    Logger.debug("Received site visit")
    # TODO: Update your stats storage
    # stats = YourStats.increment_site_visit()
    stats = %{visits: 0}
    Phoenix.PubSub.broadcast(@pubsub, "stats:site", {:site_stats_updated, stats})
    {:noreply, state}
  end

  def handle_info({:blog_visit, slug}, state) do
    Logger.debug("Received blog visit for #{slug}")
    # TODO: Update your stats storage
    # stats = YourStats.increment_visit(slug)
    stats = %{visits: 0, likes: 0, comments: []}
    broadcast_stats(slug, stats)
    {:noreply, state}
  end

  def handle_info({:blog_like, slug}, state) do
    Logger.debug("Received blog like for #{slug}")
    # TODO: Update your stats storage
    # stats = YourStats.increment_likes(slug)
    stats = %{visits: 0, likes: 0, comments: []}
    broadcast_stats(slug, stats)
    {:noreply, state}
  end

  def handle_info({:blog_comment, slug, comment_data}, state) do
    Logger.debug("Received blog comment for #{slug}: #{inspect(comment_data)}")
    # TODO: Update your stats storage
    # stats = YourStats.add_comment(slug, comment_data)
    stats = %{visits: 0, likes: 0, comments: []}
    broadcast_stats(slug, stats)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warning("Unknown message received: #{inspect(msg)}")
    {:noreply, state}
  end

  defp broadcast_stats(slug, stats) do
    topic = "stats:blog:#{slug}"
    Phoenix.PubSub.broadcast(@pubsub, topic, {:stats_updated, stats})
    Logger.debug("Broadcasted stats update for #{slug}: #{inspect(stats)}")
  end
end
```

---

## 3. Cluster Configuration

Ensure Accumulator joins the same cluster as EventHorizon.

**File:** `config/runtime.exs`

```elixir
# Example for Fly.io
if config_env() == :prod do
  app_name = System.get_env("FLY_APP_NAME")

  config :libcluster,
    topologies: [
      fly6pn: [
        strategy: Cluster.Strategy.DNSPoll,
        config: [
          polling_interval: 5_000,
          query: "#{app_name}.internal",
          node_basename: app_name
        ]
      ]
    ]
end
```

---

## Event Contract

| Event | Payload | Action |
|-------|---------|--------|
| `{:site_visit}` | none | Increment site visits, broadcast stats |
| `{:blog_visit, slug}` | `slug :: String.t()` | Increment blog visits, broadcast stats |
| `{:blog_like, slug}` | `slug :: String.t()` | Increment likes, broadcast stats |
| `{:blog_comment, slug, data}` | `slug :: String.t(), data :: map()` | Add comment, broadcast stats |

---

## Response Contract

| Topic | Message | Payload |
|-------|---------|---------|
| `"stats:site"` | `{:site_stats_updated, stats}` | `%{visits: int}` |
| `"stats:blog:#{slug}"` | `{:stats_updated, stats}` | `%{visits: int, likes: int, comments: list}` |
