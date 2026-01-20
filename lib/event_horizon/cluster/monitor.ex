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

  alias EventHorizon.Cluster.Outbox

  defstruct [:remote_node_prefix, connected_nodes: MapSet.new()]

  # Public APIs

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Returns true if connected to at least one remote node."
  @spec connected?() :: boolean()
  def connected?() do
    GenServer.call(__MODULE__, :connected?)
  end

  @doc "Returns list of currently connected nodes."
  @spec connected_nodes() :: [node()]
  def connected_nodes() do
    GenServer.call(__MODULE__, :connected_nodes)
  end

  @doc "Returns the connected remote app node (filtered by prefix)."
  @spec remote_node() :: node()
  def remote_node() do
    GenServer.call(__MODULE__, :remote_node)
  end

  # Callbacks

  @impl true
  def init(_opts) do
    # Subscribe to node events
    :net_kernel.monitor_nodes(true, node_type: :visible)

    remote_node_prefix =
      Application.get_env(:event_horizon, :remote_node_prefix, "phoenix-aayushsahu-com")

    initial_nodes = Node.list() |> MapSet.new()

    Logger.info(
      "Cluster Monitoring started. Initial nodes: #{inspect(MapSet.to_list(initial_nodes))}"
    )

    {:ok, %__MODULE__{remote_node_prefix: remote_node_prefix, connected_nodes: initial_nodes}}
  end

  @impl true
  def handle_call(:connected?, _, state) do
    {:reply, MapSet.size(state.connected_nodes) > 0, state}
  end

  @impl true
  def handle_call(:connected_nodes, _from, state) do
    {:reply, MapSet.to_list(state.connected_nodes), state}
  end

  @impl true
  def handle_call(:remote_node, _from, state) do
    remote_node =
      state.connected_nodes
      |> Enum.filter(&is_remote_node?(&1, state.remote_node_prefix))
      |> Enum.at(0)

    {:reply, remote_node, state}
  end

  @impl true
  def handle_info({:nodeup, node, _info}, state) do
    Logger.info("Node connected: #{node}")

    state = %{state | connected_nodes: MapSet.put(state.connected_nodes, node)}

    if is_remote_node?(node, state.remote_node_prefix) do
      Outbox.trigger_sync(node)
    end

    {:noreply, state}
  end

  def handle_info({:nodedown, node, _info}, state) do
    Logger.warning("Node disconnected: #{node}")

    state = %{state | connected_nodes: MapSet.delete(state.connected_nodes, node)}

    {:noreply, state}
  end

  defp is_remote_node?(node, prefix) do
    node |> Atom.to_string() |> String.starts_with?(prefix)
  end
end
