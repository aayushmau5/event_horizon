defmodule EventHorizonWeb.BlogLive.Index do
  use EventHorizonWeb, :live_view

  alias EventHorizon.Blog

  @impl true
  def mount(_params, _session, socket) do
    blogs = Blog.all_blogs()
    all_tags = get_all_tags(blogs)

    {:ok,
     socket
     |> assign(
       all_blogs: blogs,
       filtered_blogs: blogs,
       all_tags: all_tags,
       search_query: "",
       selected_tag: "",
       selected_category: "tech"
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

    selected_tag =
      if selected_category == "life-opinions-misc", do: "", else: selected_tag

    {:noreply,
     socket
     |> assign(
       search_query: search_query,
       selected_tag: selected_tag,
       selected_category: selected_category
     )
     |> apply_filters()}
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

  defp update_url(socket, query \\ nil, tag \\ nil, category \\ nil) do
    query = query || socket.assigns.search_query
    tag = tag || socket.assigns.selected_tag
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

  defp apply_filters(socket) do
    %{
      all_blogs: all_blogs,
      search_query: search_query,
      selected_tag: selected_tag,
      selected_category: selected_category
    } = socket.assigns

    filtered =
      all_blogs
      |> filter_by_search(search_query)
      |> filter_by_category(selected_category)
      |> filter_by_tag(selected_tag)

    assign(socket, filtered_blogs: filtered)
  end

  defp filter_by_search(blogs, ""), do: blogs

  defp filter_by_search(blogs, query) do
    query_lower = String.downcase(query)

    Enum.filter(blogs, fn blog ->
      String.contains?(String.downcase(blog.title), query_lower)
    end)
  end

  defp filter_by_category(blogs, "tech") do
    Enum.filter(blogs, fn blog ->
      not has_tag?(blog, ["life", "misc", "opinions"])
    end)
  end

  defp filter_by_category(blogs, "life-opinions-misc") do
    Enum.filter(blogs, fn blog ->
      has_tag?(blog, ["life", "misc", "opinions"])
    end)
  end

  defp filter_by_category(blogs, _), do: blogs

  defp filter_by_tag(blogs, ""), do: blogs

  defp filter_by_tag(blogs, tag) do
    Enum.filter(blogs, fn blog ->
      has_tag?(blog, [tag])
    end)
  end

  defp has_tag?(blog, tags) do
    Enum.any?(tags, fn tag ->
      tag in (blog.tags || [])
    end)
  end

  defp get_all_tags(blogs) do
    blogs
    |> Enum.flat_map(& &1.tags)
    |> Enum.uniq()
    |> Enum.reject(&(&1 in ["life", "misc", "opinions", "reflection"]))
    |> Enum.sort()
  end

  defp format_date(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _offset} ->
        Calendar.strftime(datetime, "%B %d, %Y")

      _ ->
        date_string
    end
  end

  defp format_date(%Date{} = date) do
    Calendar.strftime(date, "%B %d, %Y")
  end

  defp format_date(date), do: to_string(date)
end
