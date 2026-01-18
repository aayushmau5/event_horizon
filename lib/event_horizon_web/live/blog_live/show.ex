defmodule EventHorizonWeb.BlogLive.Show do
  use EventHorizonWeb, :live_view

  alias EventHorizon.Blog.Article

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case EventHorizon.Blog.get_blog(String.downcase(slug)) do
      nil ->
        {:ok, push_navigate(socket, to: "/not-found")}

      post ->
        adjacent_posts = EventHorizon.Blog.get_adjacent_articles(post.slug)
        {:ok, socket |> assign(post: post, adjacent_posts: adjacent_posts)}
    end
  end
end
