defmodule EventHorizonWeb.BlogComponents.Counter do
  @moduledoc """
  An interactive counter component for blog posts.

  Usage in markdown:
      <.counter id="my-counter" />
  """
  use EventHorizonWeb, :live_component

  def mount(socket) do
    {:ok, assign(socket, count: 0)}
  end

  def handle_event("inc", _, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def handle_event("dec", _, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

  def render(assigns) do
    ~H"""
    <div class="flex items-center gap-4 p-6 bg-white/10 rounded-xl my-6 not-prose">
      <div>{@count}</div>
      <button
        phx-click="dec"
        phx-target={@myself}
        class="w-10 h-10 rounded-full bg-red-500 text-white text-xl font-bold"
      >
        -
      </button>
      <button
        phx-click="inc"
        phx-target={@myself}
        class="w-10 h-10 rounded-full bg-green-500 text-white text-xl font-bold"
      >
        +
      </button>
    </div>
    """
  end
end
