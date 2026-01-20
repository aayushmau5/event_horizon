defmodule EventHorizon.Cluster do
  @moduledoc """
  Facade for remote metric operations.

  Automatically buffers events if cluster is disconnected.
  Uses RPC for real-time calls when connected.
  """

  require Logger
  alias EventHorizon.Cluster.{Monitor, Outbox}

  @rpc_timeout 5_000

  @type(event_types :: :increment_visit, :like_blog, :comment_blog)

  def increment_visit(page_id) do
    execute_or_buffer(:increment_visit, %{page_id: page_id})
  end

  def update_likes(post_id) do
    execute_or_buffer(:update_likes, %{post_id: post_id})
  end

  def add_comment(post_id, comment_data) do
    execute_or_buffer(:add_comment, %{post_id: post_id, comment: comment_data})
  end

  defp execute_or_buffer(event_type, payload) do
    case Monitor.remote_node() do
      nil ->
        # Buffer
        Outbox.enqueue(event_type, payload)
        {:ok, :buffered}

      node ->
        :erpc.call(node, Accumulator.Remote.Handler, event_type, payload, @rpc_timeout)
    end
  rescue
    e in ErlangError ->
      Logger.warning("RPC failed, Buffering: #{inspect(e.original)}")
      buffer_event(event_type, payload)
  end

  defp buffer_event(event_type, payload) do
    Outbox.enqueue(event_type, payload)
    {:ok, :buffered}
  end
end
