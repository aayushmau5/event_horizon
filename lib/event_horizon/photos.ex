defmodule EventHorizon.Photos do
  @moduledoc """
  Fetches the public photo list from Accumulator's `/api/photos` endpoint.
  """

  require Logger

  def list_photos do
    case Req.get(api_url(),
           receive_timeout: 3_000,
           retry: false,
           connect_options: [transport_opts: [inet6: true]]
         ) do
      {:ok, %Req.Response{status: 200, body: %{"photos" => photos}}} when is_list(photos) ->
        {:ok, Enum.map(photos, &to_photo/1)}

      {:ok, %Req.Response{status: 200}} ->
        Logger.warning("Photos API returned an unexpected body")
        {:error, :unexpected_body}

      {:ok, %Req.Response{status: status}} ->
        Logger.warning("Photos API returned status #{status}")
        {:error, {:http_status, status}}

      {:error, exception} ->
        Logger.warning("Photos API request failed: #{Exception.message(exception)}")
        {:error, exception}
    end
  end

  defp to_photo(photo) do
    %{
      id: photo["id"],
      caption: photo["caption"],
      place: photo["place"],
      taken_at: parse_datetime(photo["taken_at"]),
      width: photo["width"],
      height: photo["height"],
      thumb_url: photo["thumb_url"],
      full_url: photo["full_url"]
    }
  end

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      {:error, _reason} -> nil
    end
  end

  defp parse_datetime(_value), do: nil

  defp api_url, do: Application.fetch_env!(:event_horizon, :photos_api_url)
end
