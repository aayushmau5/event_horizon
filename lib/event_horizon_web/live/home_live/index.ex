defmodule EventHorizonWeb.HomeLive.Index do
  use EventHorizonWeb, :live_view

  alias EventHorizon.Blog

  @impl true
  def mount(_params, _session, socket) do
    recent_posts = Blog.recent_articles(3)
    {:ok, socket |> assign(recent_posts: recent_posts)}
  end

  defp format_date(%Date{} = date) do
    Calendar.strftime(date, "%B %d, %Y")
  end
end
