defmodule EventHorizonWeb.BlogLive.Index do
  use EventHorizonWeb, :live_view

  alias EventHorizon.Blog

  @impl true
  def mount(_params, _session, socket) do
    blogs = Blog.list_blogs()
    {:ok, socket |> assign(blogs: blogs)}
  end
end
