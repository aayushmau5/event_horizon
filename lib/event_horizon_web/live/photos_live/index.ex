defmodule EventHorizonWeb.PhotosLive.Index do
  use EventHorizonWeb, :live_view

  alias EventHorizon.Photos

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Photos | Aayush Sahu", selected: nil, selected_index: nil)
     |> assign_async([:months, :photos], &fetch_photos/0)}
  end

  @impl true
  def handle_event("open", %{"id" => id}, socket) do
    index = Enum.find_index(loaded_photos(socket), &(to_string(&1.id) == id))
    {:noreply, select(socket, index)}
  end

  def handle_event("step", _params, %{assigns: %{selected_index: nil}} = socket) do
    {:noreply, socket}
  end

  def handle_event("step", %{"dir" => dir}, socket) do
    offset = if dir == "next", do: 1, else: -1
    index = socket.assigns.selected_index + offset

    if index >= 0 and index < length(loaded_photos(socket)) do
      {:noreply, select(socket, index)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("close", _params, socket) do
    {:noreply, select(socket, nil)}
  end

  defp select(socket, nil), do: assign(socket, selected: nil, selected_index: nil)

  defp select(socket, index) do
    assign(socket,
      selected: Enum.at(loaded_photos(socket), index),
      selected_index: index
    )
  end

  defp loaded_photos(%{assigns: %{photos: %{ok?: true, result: photos}}}), do: photos
  defp loaded_photos(_socket), do: []

  defp fetch_photos do
    with {:ok, photos} <- Photos.list_photos() do
      photos = newest_first(photos)
      {:ok, %{months: group_by_month(photos), photos: photos}}
    end
  end

  defp newest_first(photos) do
    {dated, undated} = Enum.split_with(photos, & &1.taken_at)
    Enum.sort_by(dated, & &1.taken_at, {:desc, DateTime}) ++ undated
  end

  defp group_by_month(photos) do
    photos
    |> Enum.chunk_by(&month_key/1)
    |> Enum.map(fn [first | _] = group ->
      %{id: month_id(first), label: month_label(first), photos: group}
    end)
  end

  defp month_key(%{taken_at: nil}), do: nil
  defp month_key(%{taken_at: taken_at}), do: {taken_at.year, taken_at.month}

  defp month_id(%{taken_at: nil}), do: "undated"
  defp month_id(%{taken_at: taken_at}), do: Calendar.strftime(taken_at, "%Y-%m")

  defp month_label(%{taken_at: nil}), do: "Undated"
  defp month_label(%{taken_at: taken_at}), do: Calendar.strftime(taken_at, "%B %Y")

  defp ratio(%{width: width, height: height})
       when is_integer(width) and is_integer(height) and height > 0 do
    Float.round(width / height, 3)
  end

  defp ratio(_photo), do: 1
end
