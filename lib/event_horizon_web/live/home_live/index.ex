defmodule EventHorizonWeb.HomeLive.Index do
  use EventHorizonWeb, :live_view

  alias EventHorizon.Blog

  @impl true
  def mount(_params, _session, socket) do
    recent_posts = Blog.list_blogs() |> Enum.take(3)
    {:ok, socket |> assign(recent_posts: recent_posts)}
  end

  defp format_date(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _offset} ->
        Calendar.strftime(datetime, "%B %d, %Y")

      _ ->
        date_string
    end
  end

  defp format_date(date) do
    Calendar.strftime(date, "%B %d, %Y")
  end
end
