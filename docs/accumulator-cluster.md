# Plan: App-2 (Accumulator) — Analytics Backend

## Overview

Accumulator stores persistent stats, handles RPC calls from EventHorizon, and returns updated stats.

---

## 1. Database Schema

### 1.1 Site Stats Table

```elixir
# priv/repo/migrations/xxx_create_site_stats.exs
create table(:site_stats, primary_key: false) do
  add :id, :string, primary_key: true  # e.g., "home", "about"
  add :visits, :integer, default: 0
  timestamps()
end
```

### 1.2 Blog Stats Table

```elixir
# priv/repo/migrations/xxx_create_blog_stats.exs
create table(:blog_stats, primary_key: false) do
  add :slug, :string, primary_key: true
  add :visits, :integer, default: 0
  add :likes, :integer, default: 0
  timestamps()
end
```

### 1.3 Comments Table

```elixir
# priv/repo/migrations/xxx_create_comments.exs
create table(:comments) do
  add :blog_slug, :string, null: false
  add :author, :string
  add :content, :text, null: false
  timestamps()
end

create index(:comments, [:blog_slug])
```

---

## 2. Schemas

**File:** `lib/accumulator/stats/site_stat.ex`

```elixir
defmodule Accumulator.Stats.SiteStat do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "site_stats" do
    field :visits, :integer, default: 0
    timestamps()
  end

  def changeset(stat, attrs) do
    stat
    |> cast(attrs, [:id, :visits])
    |> validate_required([:id])
  end
end
```

**File:** `lib/accumulator/stats/blog_stat.ex`

```elixir
defmodule Accumulator.Stats.BlogStat do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:slug, :string, autogenerate: false}
  schema "blog_stats" do
    field :visits, :integer, default: 0
    field :likes, :integer, default: 0
    timestamps()
  end

  def changeset(stat, attrs) do
    stat
    |> cast(attrs, [:slug, :visits, :likes])
    |> validate_required([:slug])
  end
end
```

**File:** `lib/accumulator/stats/comment.ex`

```elixir
defmodule Accumulator.Stats.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :blog_slug, :string
    field :author, :string
    field :content, :string
    timestamps()
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:blog_slug, :author, :content])
    |> validate_required([:blog_slug, :content])
  end
end
```

---

## 3. Stats Context

**File:** `lib/accumulator/stats.ex`

```elixir
defmodule Accumulator.Stats do
  alias Accumulator.Repo
  alias Accumulator.Stats.{SiteStat, BlogStat, Comment}
  import Ecto.Query

  # Site stats

  def increment_site_visit(page_id) do
    Repo.insert(
      %SiteStat{id: page_id, visits: 1},
      on_conflict: [inc: [visits: 1]],
      conflict_target: :id,
      returning: true
    )
  end

  def get_site_stats(page_id) do
    Repo.get(SiteStat, page_id) || %SiteStat{id: page_id, visits: 0}
  end

  def total_site_visits do
    from(s in SiteStat, select: sum(s.visits))
    |> Repo.one()
    |> Kernel.||(0)
  end

  # Blog stats

  def increment_blog_visit(slug) do
    Repo.insert(
      %BlogStat{slug: slug, visits: 1, likes: 0},
      on_conflict: [inc: [visits: 1]],
      conflict_target: :slug,
      returning: true
    )
  end

  def increment_blog_likes(slug) do
    Repo.insert(
      %BlogStat{slug: slug, visits: 0, likes: 1},
      on_conflict: [inc: [likes: 1]],
      conflict_target: :slug,
      returning: true
    )
  end

  def get_blog_stats(slug) do
    stat = Repo.get(BlogStat, slug) || %BlogStat{slug: slug, visits: 0, likes: 0}
    comments = list_comments(slug)

    %{
      visits: stat.visits,
      likes: stat.likes,
      comments: comments
    }
  end

  # Comments

  def add_comment(slug, attrs) do
    %Comment{}
    |> Comment.changeset(Map.put(attrs, :blog_slug, slug))
    |> Repo.insert()
  end

  def list_comments(slug) do
    from(c in Comment, where: c.blog_slug == ^slug, order_by: [desc: c.inserted_at])
    |> Repo.all()
  end
end
```

---

## 4. Remote Handler (RPC Entry Point)

**File:** `lib/accumulator/remote/handler.ex`

```elixir
defmodule Accumulator.Remote.Handler do
  @moduledoc """
  Entry point for RPC calls from EventHorizon.
  All functions receive a payload map and return {:ok, result} or {:error, reason}.
  """

  alias Accumulator.Stats

  # Called directly via :erpc.call

  def increment_visit(%{page_id: page_id}) do
    case Stats.increment_site_visit(page_id) do
      {:ok, stat} -> {:ok, stat.visits}
      error -> error
    end
  end

  def increment_blog_visit(%{slug: slug}) do
    case Stats.increment_blog_visit(slug) do
      {:ok, _stat} -> {:ok, Stats.get_blog_stats(slug)}
      error -> error
    end
  end

  def update_likes(%{post_id: slug}) do
    case Stats.increment_blog_likes(slug) do
      {:ok, _stat} -> {:ok, Stats.get_blog_stats(slug)}
      error -> error
    end
  end

  def add_comment(%{post_id: slug, comment: comment_data}) do
    case Stats.add_comment(slug, comment_data) do
      {:ok, _comment} -> {:ok, Stats.get_blog_stats(slug)}
      error -> error
    end
  end

  def get_blog_stats(%{slug: slug}) do
    {:ok, Stats.get_blog_stats(slug)}
  end

  def get_site_stats(%{}) do
    {:ok, %{total_visits: Stats.total_site_visits()}}
  end

  # For buffered event replay from Outbox
  def handle_buffered_event(%{type: type, payload: payload, event_id: _event_id}) do
    apply(__MODULE__, type, [payload])
  end
end
```

---

## 5. Ensure Cluster Connectivity

Make sure app-2 is configured to join the same cluster as app-1 (via libcluster/DNSCluster).

Example configuration in `config/runtime.exs`:

```elixir
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
```

---

## Summary: App-2 Responsibilities

| Component        | Responsibility                          |
| ---------------- | --------------------------------------- |
| `Stats` context  | CRUD for visits, likes, comments        |
| `Remote.Handler` | RPC entry point, returns updated stats  |
| Database         | Persistent storage with atomic increments |

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                       App-2 (Accumulator)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  :erpc.call from App-1                                          │
│       │                                                         │
│       ▼                                                         │
│  Remote.Handler.increment_blog_visit(%{slug: slug})             │
│       │                                                         │
│       ▼                                                         │
│  Stats.increment_blog_visit(slug)                               │
│       │                                                         │
│       ▼                                                         │
│  Repo.insert(..., on_conflict: [inc: [visits: 1]])              │
│       │                                                         │
│       ▼                                                         │
│  Stats.get_blog_stats(slug)                                     │
│       │                                                         │
│       ▼                                                         │
│  Return {:ok, %{visits: N, likes: M, comments: [...]}}          │
│       │                                                         │
│       ▼                                                         │
│  Response sent back to App-1 via :erpc                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## API Contract

| Function              | Payload                                  | Returns                                      |
| --------------------- | ---------------------------------------- | -------------------------------------------- |
| `increment_visit`     | `%{page_id: string}`                     | `{:ok, integer}` (new count)                 |
| `increment_blog_visit`| `%{slug: string}`                        | `{:ok, %{visits, likes, comments}}`          |
| `update_likes`        | `%{post_id: string}`                     | `{:ok, %{visits, likes, comments}}`          |
| `add_comment`         | `%{post_id: string, comment: map}`       | `{:ok, %{visits, likes, comments}}`          |
| `get_blog_stats`      | `%{slug: string}`                        | `{:ok, %{visits, likes, comments}}`          |
| `get_site_stats`      | `%{}`                                    | `{:ok, %{total_visits: integer}}`            |
| `handle_buffered_event`| `%{type, payload, event_id}`            | Result of dispatched function                |
