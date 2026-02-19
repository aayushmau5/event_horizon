defmodule EventHorizon.ChatBuffer do
  @moduledoc """
  In-memory ring buffer for recent chat messages.
  New connections receive the last N messages on mount.
  """

  use Agent

  @max_messages 50

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def push(message) do
    Agent.update(__MODULE__, fn messages ->
      [message | messages] |> Enum.take(@max_messages)
    end)
  end

  def recent do
    Agent.get(__MODULE__, fn messages -> Enum.reverse(messages) end)
  end
end
