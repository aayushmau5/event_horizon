defmodule EventHorizon.LatencyTest do
  use ExUnit.Case, async: false

  alias EventHorizon.Latency

  setup do
    # Stop any existing latency process
    case Process.whereis(Latency) do
      nil -> :ok
      pid -> GenServer.stop(pid)
    end

    :ok
  end

  describe "GenServer stability" do
    test "does not crash when erpc times out" do
      # Start the latency GenServer with a very short interval
      {:ok, pid} = Latency.start_link(interval_ms: 100)

      # Give it time to attempt measurements (nodes won't exist in test env)
      Process.sleep(250)

      # Verify the GenServer is still alive
      assert Process.alive?(pid)

      # Should be able to get latencies even if they're errors
      latencies = Latency.get_latencies()

      assert is_map(latencies)
      assert Map.has_key?(latencies, :eh_to_phx)
      assert Map.has_key?(latencies, :eh_to_bsh)
      assert Map.has_key?(latencies, :phx_to_bsh)

      # Clean up
      GenServer.stop(pid)
    end

    test "continues to schedule measurements after errors" do
      {:ok, pid} = Latency.start_link(interval_ms: 50)

      # Wait for multiple measurement cycles
      Process.sleep(200)

      # GenServer should still be running
      assert Process.alive?(pid)

      # Clean up
      GenServer.stop(pid)
    end

    test "broadcasts latency updates via PubSub" do
      # Subscribe to latency updates
      :ok = Latency.subscribe()

      {:ok, pid} = Latency.start_link(interval_ms: 50)

      # Should receive at least one latency update
      assert_receive {:latency_updated, latencies}, 200

      assert is_map(latencies)

      # Clean up
      GenServer.stop(pid)
    end
  end

  describe "get_latencies/0" do
    test "returns current latency state" do
      {:ok, pid} = Latency.start_link(interval_ms: 1000)

      latencies = Latency.get_latencies()

      assert is_map(latencies)
      assert Map.has_key?(latencies, :eh_to_phx)
      assert Map.has_key?(latencies, :eh_to_bsh)
      assert Map.has_key?(latencies, :phx_to_bsh)

      # Clean up
      GenServer.stop(pid)
    end
  end
end
