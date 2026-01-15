defmodule EventHorizonWeb.BlogLive.Index do
  use EventHorizonWeb, :live_view

  alias EventHorizon.Blog

  @impl true
  def mount(_params, _session, socket) do
    blogs = Blog.list_blogs()
    {:ok, socket |> assign(blogs: blogs)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-2 p-2">
      <.link :for={blog <- @blogs} class="p-2 border rounded-md" href={"/blog/#{blog.slug}"}>
        {blog.title}
      </.link>
    </div>
    """
  end
end
