# Elixir Clustering Plan: EventHorizon ↔ Phoenix.aayushsahu.com

## Overview

This document outlines the plan to cluster the `event_horizon` app with `phoenix.aayushsahu.com` on Fly.io, enabling real-time metrics synchronization, PubSub communication, and remote function calls.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Fly.io Private Network (6PN)                    │
│                                                                              │
│  ┌──────────────────────────┐         ┌──────────────────────────────────┐  │
│  │   event_horizon          │         │   phoenix.aayushsahu.com         │  │
│  │   (aayush-event-horizon) │  ◄───►  │   (existing clustered app)       │  │
│  │                          │         │                                  │  │
│  │  ┌────────────────────┐  │         │  ┌────────────────────────────┐  │  │
│  │  │ Cluster.Manager    │  │  Node   │  │ Metrics.Handler            │  │  │
│  │  │ - Connect/Retry    │──┼─Connect─┼──│ - increment_visit/2        │  │  │
│  │  │ - Monitor nodes    │  │         │  │ - update_likes/2           │  │  │
│  │  └────────────────────┘  │         │  │ - get_realtime_count/1     │  │  │
│  │                          │         │  └────────────────────────────┘  │  │
│  │  ┌────────────────────┐  │         │                                  │  │
│  │  │ Buffer.Outbox      │  │         │  ┌────────────────────────────┐  │  │
│  │  │ - ETS storage      │  │  PubSub │  │ Phoenix.PubSub             │  │  │
│  │  │ - Queue events     │  │◄───────►│  │ - broadcast events         │  │  │
│  │  │ - Replay on connect│  │         │  │ - subscribe/unsubscribe    │  │  │
│  │  └────────────────────┘  │         │  └────────────────────────────┘  │  │
│  │                          │         │                                  │  │
│  │  ┌────────────────────┐  │         │                                  │  │
│  │  │ Remote.Metrics     │  │   RPC   │                                  │  │
│  │  │ (Facade for calls) │──┼────────►│                                  │  │
│  │  └────────────────────┘  │         │                                  │  │
│  └──────────────────────────┘         └──────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### 1. Same Fly.io Organization
Both apps **must** be in the same Fly.io organization to use the private 6PN network.

### 2. Shared Erlang Cookie
Both apps **must** use the same `RELEASE_COOKIE`. Generate one:

```elixir
Base.url_encode64(:crypto.strong_rand_bytes(40))
```

Set in both apps via Fly secrets:
```bash
fly secrets set RELEASE_COOKIE="your-generated-cookie" -a aayush-event-horizon
fly secrets set RELEASE_COOKIE="your-generated-cookie" -a phoenix-aayushsahu  # existing app
```

### 3. Confirm Remote App's Node Naming
**CRITICAL**: You must know how `phoenix.aayushsahu.com` names its nodes. Check the remote app's `rel/env.sh.eex` or runtime config. Common pattern:

```
<app-name>@<FLY_PRIVATE_IP>
```

---

## Implementation Plan

### Phase 1: Configuration & Infrastructure

#### 1.1 Update `rel/env.sh.eex`

```bash
#!/bin/sh

# IPv6 distribution (required for Fly.io 6PN)
export ERL_AFLAGS="-proto_dist inet6_tcp"

# Node naming - unique per machine
export RELEASE_DISTRIBUTION="name"
export RELEASE_NODE="event-horizon-${FLY_MACHINE_ID}@${FLY_PRIVATE_IP}"

# Cookie from secrets (set via fly secrets)
# RELEASE_COOKIE is already picked up from env
```

#### 1.2 Update `fly.toml`

Add cluster configuration:

```toml
[env]
  PHX_HOST = 'aayush-event-horizon.fly.dev'
  PORT = '8080'
  # Remote app to cluster with
  CLUSTER_REMOTE_APP = 'phoenix-aayushsahu'  # Fly app name of phoenix.aayushsahu.com
```

#### 1.3 Runtime Configuration (`config/runtime.exs`)

```elixir
if config_env() == :prod do
  # DNS queries for clustering - includes both apps
  config :event_horizon, :dns_cluster_query, [
    # Intra-app clustering (your own instances)
    "aayush-event-horizon.internal",
    # Cross-app clustering (phoenix.aayushsahu.com)
    System.get_env("CLUSTER_REMOTE_DNS") || "phoenix-aayushsahu.internal"
  ]
  
  # Prefix to identify remote nodes (for buffer sync targeting)
  config :event_horizon, :remote_node_prefix, "phoenix"
end
```

That's it - `dns_cluster` handles discovery, connection, and retry internally.

---

### Phase 2: Core Modules

#### 2.1 Using DNSCluster (Already Installed)

`dns_cluster` handles DNS discovery and node connections. Configure it for **multiple queries** - one for your app, one for the remote app:

**Update `config/runtime.exs`:**

```elixir
# Cluster configuration
if config_env() == :prod do
  # DNS queries for clustering - includes both apps
  config :event_horizon, :dns_cluster_query, [
    # Intra-app clustering (your own instances)
    "aayush-event-horizon.internal",
    # Cross-app clustering (phoenix.aayushsahu.com)
    System.get_env("CLUSTER_REMOTE_DNS") || "phoenix-aayushsahu.internal"
  ]
end
```

**How it works:**
- `dns_cluster` periodically queries all DNS entries
- Resolves IPs and constructs node names
- Calls `Node.connect/1` for each discovered node
- Handles reconnection automatically

**Note:** Both apps must use the **same node naming convention** for dns_cluster to work across apps. The default is `<app>@<ip>`.

#### 2.2 Cluster.Monitor (GenServer)

Monitors node connections and triggers buffer sync. Discovery/connection is handled by `dns_cluster`.

```elixir
# lib/event_horizon/cluster/monitor.ex
defmodule EventHorizon.Cluster.Monitor do
  @moduledoc """
  Monitors cluster connections and triggers buffer sync on reconnection.
  
  Discovery and connection is handled by DNSCluster - this module only:
  - Monitors node up/down events
  - Triggers buffer sync on reconnection
  - Provides connection status API
  """

  use GenServer
  require Logger

  alias EventHorizon.Buffer.Outbox

  defstruct [:remote_prefix, connected_nodes: MapSet.new()]

  # ============================================================================
  # Public API
  # ============================================================================

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Returns true if connected to at least one remote node."
  @spec connected?() :: boolean()
  def connected? do
    GenServer.call(__MODULE__, :connected?)
  end

  @doc "Returns list of currently connected nodes."
  @spec connected_nodes() :: [node()]
  def connected_nodes do
    GenServer.call(__MODULE__, :connected_nodes)
  end

  @doc "Returns list of connected remote app nodes (filtered by prefix)."
  @spec remote_nodes() :: [node()]
  def remote_nodes do
    GenServer.call(__MODULE__, :remote_nodes)
  end

  # ============================================================================
  # GenServer Callbacks
  # ============================================================================

  @impl true
  def init(opts) do
    # Subscribe to node events
    :net_kernel.monitor_nodes(true, node_type: :visible)
    
    # Get remote prefix from opts or config (runtime)
    remote_prefix = 
      Keyword.get(opts, :remote_prefix) ||
      Application.get_env(:event_horizon, :remote_node_prefix, "phoenix")
    
    # Capture any already-connected nodes
    initial_nodes = Node.list() |> MapSet.new()
    
    Logger.info("Cluster.Monitor started, initial nodes: #{inspect(MapSet.to_list(initial_nodes))}")
    
    {:ok, %__MODULE__{connected_nodes: initial_nodes, remote_prefix: remote_prefix}}
  end

  @impl true
  def handle_call(:connected?, _from, state) do
    {:reply, MapSet.size(state.connected_nodes) > 0, state}
  end

  @impl true
  def handle_call(:connected_nodes, _from, state) do
    {:reply, MapSet.to_list(state.connected_nodes), state}
  end

  @impl true
  def handle_call(:remote_nodes, _from, state) do
    remote = 
      state.connected_nodes
      |> Enum.filter(&is_remote_node?(&1, state.remote_prefix))
      |> Enum.to_list()
    
    {:reply, remote, state}
  end

  @impl true
  def handle_info({:nodeup, node, _info}, state) do
    Logger.info("Node connected: #{node}")
    
    state = %{state | connected_nodes: MapSet.put(state.connected_nodes, node)}
    
    # Trigger buffer sync for remote nodes
    if is_remote_node?(node, state.remote_prefix) do
      Outbox.trigger_sync(node)
    end
    
    {:noreply, state}
  end

  @impl true
  def handle_info({:nodedown, node, _info}, state) do
    Logger.warning("Node disconnected: #{node}")
    
    state = %{state | connected_nodes: MapSet.delete(state.connected_nodes, node)}
    
    {:noreply, state}
  end

  # ============================================================================
  # Private Functions
  # ============================================================================

  defp is_remote_node?(node, prefix) do
    node
    |> Atom.to_string()
    |> String.starts_with?(prefix)
  end
end
```

#### 2.3 Buffer.Outbox (ETS-backed queue)

Stores events when disconnected, replays on reconnection.

```elixir
# lib/event_horizon/buffer/outbox.ex
defmodule EventHorizon.Buffer.Outbox do
  @moduledoc """
  ETS-backed outbox for buffering events during cluster disconnection.
  
  Uses :ordered_set for FIFO ordering with monotonic keys.
  Events include unique IDs for idempotent replay.
  """

  use GenServer
  require Logger

  @table_name :cluster_outbox
  @max_entries 10_000

  defstruct [:table, syncing: false]

  # ============================================================================
  # Public API
  # ============================================================================

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Enqueue an event to be sent when cluster reconnects.
  
  ## Parameters
  - type: Atom identifying the event type (e.g., :increment_visit)
  - payload: Map of event data
  - event_id: Optional unique ID for idempotency (auto-generated if nil)
  """
  @spec enqueue(atom(), map(), String.t() | nil) :: :ok | {:error, :buffer_full}
  def enqueue(type, payload, event_id \\ nil) do
    GenServer.call(__MODULE__, {:enqueue, type, payload, event_id})
  end

  @doc "Trigger sync to a specific node."
  @spec trigger_sync(node()) :: :ok
  def trigger_sync(target_node) do
    GenServer.cast(__MODULE__, {:sync, target_node})
  end

  @doc "Returns current queue size."
  @spec queue_size() :: non_neg_integer()
  def queue_size do
    GenServer.call(__MODULE__, :queue_size)
  end

  @doc "Returns all queued events (for debugging)."
  @spec peek() :: [map()]
  def peek do
    GenServer.call(__MODULE__, :peek)
  end

  # ============================================================================
  # GenServer Callbacks
  # ============================================================================

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:ordered_set, :protected, :named_table])
    Logger.info("Buffer.Outbox initialized with table #{@table_name}")
    {:ok, %__MODULE__{table: table}}
  end

  @impl true
  def handle_call({:enqueue, type, payload, event_id}, _from, state) do
    current_size = :ets.info(state.table, :size)

    if current_size >= @max_entries do
      Logger.warning("Outbox buffer full (#{@max_entries} entries), dropping event")
      {:reply, {:error, :buffer_full}, state}
    else
      event_id = event_id || generate_event_id()
      key = {System.monotonic_time(:nanosecond), event_id}
      
      event = %{
        event_id: event_id,
        type: type,
        payload: payload,
        inserted_at: DateTime.utc_now()
      }

      :ets.insert(state.table, {key, event})
      Logger.debug("Buffered event #{event_id} of type #{type}")
      
      {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call(:queue_size, _from, state) do
    {:reply, :ets.info(state.table, :size), state}
  end

  @impl true
  def handle_call(:peek, _from, state) do
    events = 
      :ets.tab2list(state.table)
      |> Enum.map(fn {_key, event} -> event end)

    {:reply, events, state}
  end

  @impl true
  def handle_cast({:sync, target_node}, %{syncing: true} = state) do
    Logger.debug("Sync already in progress, skipping")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:sync, target_node}, state) do
    state = %{state | syncing: true}
    
    Task.Supervisor.start_child(EventHorizon.TaskSupervisor, fn ->
      drain_to_node(state.table, target_node)
      GenServer.cast(__MODULE__, :sync_complete)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_cast(:sync_complete, state) do
    {:noreply, %{state | syncing: false}}
  end

  # ============================================================================
  # Private Functions
  # ============================================================================

  defp drain_to_node(table, target_node) do
    entries = :ets.tab2list(table)
    
    count =
      Enum.reduce_while(entries, 0, fn {key, event}, acc ->
        case replay_event(target_node, event) do
          :ok ->
            :ets.delete(table, key)
            {:cont, acc + 1}

          {:error, reason} ->
            Logger.warning("Failed to replay event #{event.event_id}: #{inspect(reason)}")
            {:halt, acc}
        end
      end)

    Logger.info("Outbox sync complete, sent #{count} events")
  end

  defp replay_event(target_node, event) do
    :erpc.call(target_node, EventHorizon.Remote.Handler, :handle_buffered_event, [event], 5_000)
  rescue
    e in ErlangError -> {:error, e.original}
  end

  defp generate_event_id do
    Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)
  end
end
```

#### 2.4 Remote.Metrics (Facade for Remote Calls)

Provides a clean API for calling remote functions.

```elixir
# lib/event_horizon/remote/metrics.ex
defmodule EventHorizon.Remote.Metrics do
  @moduledoc """
  Facade for remote metric operations.
  
  Automatically buffers events if cluster is disconnected.
  Uses RPC for real-time calls when connected.
  """

  require Logger

  alias EventHorizon.Cluster.Monitor
  alias EventHorizon.Buffer.Outbox

  @timeout 5_000

  # ============================================================================
  # Visit Tracking
  # ============================================================================

  @doc "Increment visit count for a page/post."
  @spec increment_visit(String.t(), pos_integer()) :: :ok | {:buffered, String.t()}
  def increment_visit(page_id, delta \\ 1) do
    execute_or_buffer(
      :increment_visit,
      %{page_id: page_id, delta: delta},
      {Remote.Metrics, :increment_visit, [page_id, delta]}
    )
  end

  # ============================================================================
  # Likes
  # ============================================================================

  @doc "Update like count for a post."
  @spec update_likes(String.t(), integer()) :: :ok | {:buffered, String.t()}
  def update_likes(post_id, delta) do
    execute_or_buffer(
      :update_likes,
      %{post_id: post_id, delta: delta},
      {Remote.Metrics, :update_likes, [post_id, delta]}
    )
  end

  # ============================================================================
  # Comments
  # ============================================================================

  @doc "Add a comment to a post."
  @spec add_comment(String.t(), map()) :: :ok | {:buffered, String.t()}
  def add_comment(post_id, comment_data) do
    execute_or_buffer(
      :add_comment,
      %{post_id: post_id, comment: comment_data},
      {Remote.Metrics, :add_comment, [post_id, comment_data]}
    )
  end

  # ============================================================================
  # Real-time Counts (Read Operations)
  # ============================================================================

  @doc """
  Get real-time count for a metric.
  
  Read operations are not buffered - they return an error if disconnected.
  """
  @spec get_realtime_count(String.t()) :: {:ok, non_neg_integer()} | {:error, :disconnected | :rpc_failed}
  def get_realtime_count(metric_key) do
    case get_connected_node() do
      nil ->
        {:error, :disconnected}

      node ->
        {:ok, :erpc.call(node, Remote.Metrics, :get_count, [metric_key], @timeout)}
    end
  rescue
    e in ErlangError ->
      Logger.error("RPC failed for get_realtime_count: #{inspect(e.original)}")
      {:error, :rpc_failed}
  end

  # ============================================================================
  # PubSub Subscription
  # ============================================================================

  @doc """
  Subscribe to real-time metric updates via PubSub.
  
  Messages are broadcast from the remote node when metrics change.
  """
  @spec subscribe_to_metrics(String.t()) :: :ok | {:error, :disconnected}
  def subscribe_to_metrics(topic) do
    # Subscribe locally - PubSub broadcasts propagate across connected nodes
    Phoenix.PubSub.subscribe(EventHorizon.PubSub, "metrics:#{topic}")
    :ok
  end

  @doc "Unsubscribe from metric updates."
  @spec unsubscribe_from_metrics(String.t()) :: :ok
  def unsubscribe_from_metrics(topic) do
    Phoenix.PubSub.unsubscribe(EventHorizon.PubSub, "metrics:#{topic}")
    :ok
  end

  # ============================================================================
  # Private Functions
  # ============================================================================

  defp execute_or_buffer(event_type, payload, {module, function, args}) do
    case get_connected_node() do
      nil ->
        buffer_event(event_type, payload)

      node ->
        :erpc.call(node, module, function, args, @timeout)
    end
  rescue
    e in ErlangError ->
      Logger.warning("RPC failed, buffering: #{inspect(e.original)}")
      buffer_event(event_type, payload)
  end

  defp buffer_event(event_type, payload) do
    event_id = generate_event_id()
    Outbox.enqueue(event_type, payload, event_id)
    {:buffered, event_id}
  end

  defp get_connected_node do
    case Monitor.remote_nodes() do
      [] -> nil
      [node | _] -> node
    end
  end

  defp generate_event_id do
    Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)
  end
end
```

#### 2.5 Remote.Handler (For receiving buffered events)

The remote app needs this module to handle replayed events.

```elixir
# lib/event_horizon/remote/handler.ex
defmodule EventHorizon.Remote.Handler do
  @moduledoc """
  Handles incoming buffered events from other nodes.
  
  This module should exist on the REMOTE app (phoenix.aayushsahu.com).
  Include it here as a reference implementation.
  """

  require Logger

  @doc """
  Handle a buffered event replayed from another node.
  
  The event includes an event_id for idempotency - implement
  deduplication on the receiving side.
  """
  @spec handle_buffered_event(map()) :: :ok | {:error, term()}
  def handle_buffered_event(%{event_id: event_id, type: type, payload: payload}) do
    Logger.debug("Received buffered event: #{event_id} type=#{type}")
    
    # TODO: Implement idempotency check
    # if already_processed?(event_id), do: return :ok
    
    case type do
      :increment_visit ->
        handle_increment_visit(payload)
        
      :update_likes ->
        handle_update_likes(payload)
        
      :add_comment ->
        handle_add_comment(payload)
        
      unknown ->
        Logger.warning("Unknown event type: #{unknown}")
        {:error, :unknown_event_type}
    end
  end

  defp handle_increment_visit(%{page_id: page_id, delta: delta}) do
    # Implement your metric update logic
    Logger.info("Incrementing visit for #{page_id} by #{delta}")
    :ok
  end

  defp handle_update_likes(%{post_id: post_id, delta: delta}) do
    Logger.info("Updating likes for #{post_id} by #{delta}")
    :ok
  end

  defp handle_add_comment(%{post_id: post_id, comment: comment}) do
    Logger.info("Adding comment to #{post_id}")
    :ok
  end
end
```

---

### Phase 3: Application Supervision Tree

Update `application.ex`:

```elixir
# lib/event_horizon/application.ex
defmodule EventHorizon.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EventHorizonWeb.Telemetry,
      # DNSCluster now handles BOTH intra-app and cross-app clustering
      {DNSCluster, query: Application.get_env(:event_horizon, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EventHorizon.PubSub},
      
      # Cluster management (add these)
      {Task.Supervisor, name: EventHorizon.TaskSupervisor},
      EventHorizon.Buffer.Outbox,
      EventHorizon.Cluster.Monitor,
      
      EventHorizonWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: EventHorizon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    EventHorizonWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
```

**Key point:** `DNSCluster` is configured with a **list of queries** in `runtime.exs` to discover both your app's instances and the remote app.

---

### Phase 4: Local Development Setup

#### 4.1 Development Scripts

Create `bin/dev-cluster`:

```bash
#!/bin/bash
# bin/dev-cluster
# Starts two nodes for local cluster testing

set -e

echo "Starting Node A (event_horizon)..."
gnome-terminal -- bash -c "cd $(pwd) && ./bin/dev-node-a; exec bash" 2>/dev/null || \
  osascript -e "tell app \"Terminal\" to do script \"cd $(pwd) && ./bin/dev-node-a\"" 2>/dev/null || \
  echo "Please run ./bin/dev-node-a in a new terminal"

sleep 2

echo "Starting Node B (simulated remote)..."
gnome-terminal -- bash -c "cd $(pwd) && ./bin/dev-node-b; exec bash" 2>/dev/null || \
  osascript -e "tell app \"Terminal\" to do script \"cd $(pwd) && ./bin/dev-node-b\"" 2>/dev/null || \
  echo "Please run ./bin/dev-node-b in a new terminal"

echo ""
echo "Two nodes should now be starting."
echo "In Node A's iex, run: Node.connect(:\"node_b@127.0.0.1\")"
echo "Verify with: Node.list()"
```

Create `bin/dev-node-a`:

```bash
#!/bin/bash
# bin/dev-node-a
# Starts event_horizon as Node A

export RELEASE_DISTRIBUTION=name
export RELEASE_NODE=event_horizon@127.0.0.1
export RELEASE_COOKIE=local_dev_cookie
export PHX_SERVER=true
export PORT=4000

# Disable remote clustering in dev (connect manually)
export CLUSTER_ENABLED=false

echo "Starting EventHorizon as node: $RELEASE_NODE"
iex --name $RELEASE_NODE --cookie $RELEASE_COOKIE -S mix phx.server
```

Create `bin/dev-node-b`:

```bash
#!/bin/bash
# bin/dev-node-b
# Simulates the remote phoenix.aayushsahu.com node

export RELEASE_DISTRIBUTION=name
export RELEASE_NODE=node_b@127.0.0.1
export RELEASE_COOKIE=local_dev_cookie
export PHX_SERVER=true
export PORT=4001

# Disable clustering
export CLUSTER_ENABLED=false

echo "Starting simulated remote node: $RELEASE_NODE"
iex --name $RELEASE_NODE --cookie $RELEASE_COOKIE -S mix phx.server
```

Make scripts executable:

```bash
chmod +x bin/dev-node-a bin/dev-node-b bin/dev-cluster
```

#### 4.2 Local Testing Commands

```elixir
# In Node A's iex:

# Connect to Node B
Node.connect(:"node_b@127.0.0.1")
#=> true

# Verify connection
Node.list()
#=> [:"node_b@127.0.0.1"]

# Test RPC
:rpc.call(:"node_b@127.0.0.1", Kernel, :node, [])
#=> :"node_b@127.0.0.1"

# Test PubSub across nodes
Phoenix.PubSub.subscribe(EventHorizon.PubSub, "test")
# On Node B:
Phoenix.PubSub.broadcast(EventHorizon.PubSub, "test", {:hello, "world"})
# Back on Node A, check mailbox:
flush()
#=> {:hello, "world"}
```

---

### Phase 5: Telemetry & Observability

Add telemetry events for monitoring:

```elixir
# lib/event_horizon/cluster/telemetry.ex
defmodule EventHorizon.Cluster.Telemetry do
  @moduledoc "Telemetry events for cluster monitoring."

  def emit_connection_event(node, status) do
    :telemetry.execute(
      [:event_horizon, :cluster, :connection],
      %{count: 1},
      %{node: node, status: status}
    )
  end

  def emit_buffer_event(action, count) do
    :telemetry.execute(
      [:event_horizon, :cluster, :buffer],
      %{count: count},
      %{action: action}
    )
  end

  def emit_rpc_event(module, function, duration_ms, status) do
    :telemetry.execute(
      [:event_horizon, :cluster, :rpc],
      %{duration_ms: duration_ms},
      %{module: module, function: function, status: status}
    )
  end
end
```

---

## Deployment Checklist

### Before First Deploy

- [ ] Generate shared cookie: `Base.url_encode64(:crypto.strong_rand_bytes(40))`
- [ ] Set cookie on both apps: `fly secrets set RELEASE_COOKIE="..."`
- [ ] Confirm both apps are in the same Fly.io organization
- [ ] Confirm remote app's node naming pattern
- [ ] Set `CLUSTER_REMOTE_APP` in fly.toml

### Verify Clustering

```bash
# SSH into event_horizon
fly ssh console -a aayush-event-horizon

# In iex:
Node.list()
# Should show remote nodes

EventHorizon.Cluster.Manager.connected?()
#=> true

EventHorizon.Cluster.Manager.connected_nodes()
#=> [:"phoenix-aayushsahu@fdaa:0:..."]
```

---

## Risks & Mitigations

### 1. Split-Brain / Network Partitions

**Risk**: Both apps accept updates while disconnected → replay can double-count.

**Mitigation**:
- Include `event_id` in all buffered events
- Remote handler should deduplicate by `event_id`
- Consider using a DB table to track processed IDs

### 2. ETS Volatility

**Risk**: ETS data is lost on restart → buffered events lost.

**Mitigation**:
- For critical events, persist to DB instead of ETS
- Or use DETS for disk-backed storage
- Log buffered event IDs for manual recovery

### 3. Cookie Compromise

**Risk**: Erlang cookie allows arbitrary code execution via RPC.

**Mitigation**:
- Store cookie in Fly secrets (not env)
- Rotate periodically
- Never expose distribution ports publicly
- Both apps already on private 6PN network

### 4. Node Discovery Drift

**Risk**: Machines scale up/down, stale node list.

**Mitigation**:
- Periodic discovery refresh (default 10s)
- Remove stale nodes from desired set
- Handle `:nodedown` events properly

### 5. PubSub Naming Mismatch

**Risk**: Apps use different PubSub names → broadcasts don't propagate.

**Mitigation**:
- Ensure both apps use the same PubSub name for cross-app topics
- Or use RPC to broadcast into the remote PubSub

---

## File Structure

```
lib/
├── event_horizon/
│   ├── application.ex          # Updated supervision tree
│   ├── cluster/
│   │   ├── monitor.ex          # Node monitoring GenServer
│   │   └── telemetry.ex        # Cluster telemetry events
│   ├── buffer/
│   │   └── outbox.ex           # ETS-backed event buffer
│   └── remote/
│       ├── metrics.ex          # Facade for remote calls
│       └── handler.ex          # Incoming event handler (reference)
├── ...
config/
├── runtime.exs                 # Cluster configuration (dns_cluster queries)
rel/
├── env.sh.eex                  # Node naming & distribution
bin/
├── dev-cluster                 # Start both dev nodes
├── dev-node-a                  # EventHorizon dev node
└── dev-node-b                  # Simulated remote node
```

---

## Next Steps

1. **Coordinate with remote app**: Confirm node naming scheme and cookie
2. **Implement modules**: Start with Manager → Discovery → Outbox → Metrics
3. **Test locally**: Use dev scripts to verify clustering works
4. **Deploy & verify**: Check `Node.list()` on production
5. **Add idempotency**: Implement event deduplication on remote side
6. **Monitor**: Add dashboards for buffer size, connection status, RPC latency

---

## References

- [Fly.io Private Networking](https://fly.io/docs/networking/private-networking/)
- [Fly.io Elixir Clustering](https://fly.io/docs/elixir/the-basics/clustering/)
- [Erlang Distribution Protocol](https://www.erlang.org/doc/apps/erts/erl_dist_protocol.html)
- [Phoenix PubSub](https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html)
