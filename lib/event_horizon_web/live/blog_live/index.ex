defmodule EventHorizonWeb.BlogLive.Index do
  use EventHorizonWeb, :live_view

  alias EventHorizon.Blog

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Blog | Aayush Sahu",
       all_tags: Blog.all_tags(),
       total_articles: length(Blog.all_articles())
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    search_query = params["q"] || ""
    selected_tag = params["t"] || ""
    selected_category = params["c"] || "tech"

    selected_category =
      if selected_category in ["tech", "life-opinions-misc"],
        do: selected_category,
        else: "tech"

    # Clear tag when switching to life category
    selected_tag = if selected_category == "life-opinions-misc", do: "", else: selected_tag

    # Use the optimized filter function from Blog context
    filtered_blogs =
      Blog.filter_articles(
        category: selected_category,
        tag: selected_tag,
        search: search_query
      )

    {:noreply,
     socket
     |> assign(
       search_query: search_query,
       selected_tag: selected_tag,
       selected_category: selected_category,
       blogs_empty?: filtered_blogs == []
     )
     |> stream(:blogs, filtered_blogs, reset: true, dom_id: &"blog-#{&1.slug}")}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, update_url(socket, query, socket.assigns.selected_tag)}
  end

  @impl true
  def handle_event("select_category", %{"category" => category}, socket) do
    new_tag = if category == "life-opinions-misc", do: "", else: socket.assigns.selected_tag
    {:noreply, update_url(socket, socket.assigns.search_query, new_tag, category)}
  end

  @impl true
  def handle_event("select_tag", %{"tag" => tag}, socket) do
    {:noreply, update_url(socket, socket.assigns.search_query, tag)}
  end

  defp update_url(socket, query, tag, category \\ nil) do
    category = category || socket.assigns.selected_category

    params =
      %{}
      |> maybe_put("q", query)
      |> maybe_put("t", tag)
      |> maybe_put("c", category, "tech")

    push_patch(socket, to: ~p"/blog?#{params}")
  end

  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value, default \\ nil)
  defp maybe_put(map, _key, value, value), do: map
  defp maybe_put(map, key, value, _default), do: Map.put(map, key, value)
end
