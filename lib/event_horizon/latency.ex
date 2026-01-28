defmodule EventHorizon.Latency do
  @moduledoc """
  Measures latency between the three clustered nodes in fly.io:
  - EH → PHX (this app to Phoenix app)
  - EH → BSH (this app to Battleship app)
  - PHX → BSH (Phoenix app to Battleship, measured via Accumulator.Latency.measure_bsh/0)
  """

  use GenServer
  require Logger

  @phx_prefix "phoenix-aayushsahu-com"
  @bsh_prefix "aayush-battleship"
  @default_interval 750
  @timeout 500

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_latencies do
    GenServer.call(__MODULE__, :latencies)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(EventHorizon.PubSub, "cluster:latency")
  end

  @impl true
  def init(opts) do
    interval_ms = Keyword.get(opts, :interval_ms, @default_interval)
    schedule_measurement(interval_ms)

    {:ok,
     %{
       interval: interval_ms,
       latencies: %{
         eh_to_phx: nil,
         eh_to_bsh: nil,
         phx_to_bsh: nil
       }
     }}
  end

  @impl true
  def handle_call(:latencies, _from, state) do
    {:reply, state.latencies, state}
  end

  @impl true
  def handle_info(:measure, state) do
    phx_node = find_node(@phx_prefix)
    bsh_node = find_node(@bsh_prefix)

    latencies = %{
      eh_to_phx: measure_rtt(phx_node),
      eh_to_bsh: measure_rtt(bsh_node),
      phx_to_bsh: measure_phx_to_bsh(phx_node)
    }

    Phoenix.PubSub.broadcast(
      EventHorizon.PubSub,
      "cluster:latency",
      {:latency_updated, latencies}
    )

    schedule_measurement(state.interval)
    {:noreply, %{state | latencies: latencies}}
  end

  defp schedule_measurement(interval) do
    Process.send_after(self(), :measure, interval)
  end

  defp find_node(prefix) do
    Node.list()
    |> Enum.find(fn node ->
      node |> Atom.to_string() |> String.starts_with?(prefix)
    end)
  end

  defp measure_rtt(nil), do: {:error, :not_connected}

  defp measure_rtt(node) do
    start_time = System.monotonic_time(:microsecond)

    try do
      :erpc.call(node, :erlang, :monotonic_time, [:native], @timeout)
    catch
      :error, {:erpc, :noconnection} ->
        Logger.warning("RPC failed: could not connect to node #{node}")
        {:error, :noconnection}

      :error, {:erpc, :timeout} ->
        Logger.warning("RPC timeout calling #{node}")
        {:error, :timeout}

      :error, {:erpc, reason} ->
        Logger.error("RPC error: #{inspect(reason)}")
        {:error, reason}

      :exit, {kind, exit} ->
        Logger.error("RPC exit: #{inspect(kind)} - #{inspect(exit)}")
        {:error, :remote_exit}
    else
      _result ->
        end_time = System.monotonic_time(:microsecond)
        rtt_ms = (end_time - start_time) / 1000.0
        {:ok, Float.round(rtt_ms, 2)}
    end
  end

  defp measure_phx_to_bsh(nil), do: {:error, :not_connected}

  defp measure_phx_to_bsh(phx_node) do
    try do
      :erpc.call(phx_node, Accumulator.Latency, :measure_bsh, [], @timeout * 2)
    catch
      :error, {:erpc, :noconnection} ->
        Logger.warning("RPC failed: could not connect to node #{phx_node}")
        {:error, :noconnection}

      :error, {:erpc, :timeout} ->
        Logger.warning("RPC timeout calling #{phx_node}")
        {:error, :timeout}

      :error, {:erpc, reason} ->
        Logger.error("RPC error: #{inspect(reason)}")
        {:error, reason}

      :exit, {kind, exit} ->
        Logger.error("RPC exit: #{inspect(kind)} - #{inspect(exit)}")
        {:error, :remote_exit}
    else
      {:ok, ms} -> {:ok, Float.round(ms / 1.0, 2)}
      {:error, _} = err -> err
    end
  end
end
