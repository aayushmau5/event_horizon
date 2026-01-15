defmodule EventHorizonWeb.BlogLive.Show do
  use EventHorizonWeb, :live_view

  alias EventHorizon.Blog.Article

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case EventHorizon.Blog.get_blog(String.downcase(slug)) do
      nil ->
        {:ok, push_navigate(socket, to: "/not-found")}

      post ->
        {:ok, socket |> assign(post: post)}
    end
  end

  @impl true
  def handle_event("inc", _, socket) do
    {:noreply, assign(socket, count: socket.assigns.count + 1)}
  end

  def handle_event("dec", _, socket) do
    {:noreply, assign(socket, count: socket.assigns.count - 1)}
  end
end
