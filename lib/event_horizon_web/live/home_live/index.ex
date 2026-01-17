defmodule EventHorizonWeb.HomeLive.Index do
  use EventHorizonWeb, :live_view

  alias EventHorizon.Blog

  @impl true
  def mount(_params, _session, socket) do
    recent_posts = Blog.recent_articles(4)
    {:ok, socket |> assign(recent_posts: recent_posts)}
  end
end
