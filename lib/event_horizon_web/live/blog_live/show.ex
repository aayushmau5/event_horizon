defmodule EventHorizonWeb.BlogLive.Show do
  use EventHorizonWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    [post] = EventHorizon.Blog.all_blogs()

    {:ok, socket |> assign(post: post) |> assign(count: 0)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 py-20 sm:px-6 lg:px-8 prose border m-2">
      {raw(@post.body)}
    </div>
    """
  end

  @impl true
  def handle_event("inc", _, socket) do
    {:noreply, assign(socket, count: socket.assigns.count + 1)}
  end

  def handle_event("dec", _, socket) do
    {:noreply, assign(socket, count: socket.assigns.count - 1)}
  end
end
