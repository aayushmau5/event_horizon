defmodule EventHorizon.Cluster.Outbox do
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

  # Public APIs

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

  # Callbacks

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:ordered_set, :protected, :named_table])
    Logger.info("Outbox buffer initialized")
    {:ok, %__MODULE__{table: table}}
  end

  @impl true
  def handle_call({:enqueue, type, payload, event_id}, _from, state) do
    current_size = :ets.info(state.table, :size)

    if current_size >= @max_entries do
      Logger.warning("Outbox full (#{@max_entries} entries), dropping event")
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
    events = :ets.tab2list(state.table) |> Enum.map(fn {_key, event} -> event end)

    {:reply, events, state}
  end

  @impl true
  def handle_cast({:sync, _target_node}, %{syncing: true} = state) do
    Logger.info("Sync already in progress, skipping")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:sync, target_node}, state) do
    state = %{state | syncing: true}
    Logger.info("Started syncing data")

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

  defp generate_event_id() do
    Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)
  end

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
    # Call remote function with the event
    :erpc.call(
      target_node,
      Accumulator.Remote.Handler,
      :handle_buffered_event,
      [event],
      # timeout
      5_000
    )
  rescue
    e in ErlangError -> {:error, e.original}
  end
end
