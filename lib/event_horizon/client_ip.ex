defmodule EventHorizon.ClientIP do
  @moduledoc """
  Extracts client IP address from LiveView socket connect_info.

  Checks proxy headers (x-forwarded-for) first, falls back to peer_data.
  """

  @doc """
  Extracts user IP from socket connect_info.
  Uses x-forwarded-for header (from proxy) or falls back to peer_data.
  """
  def get(socket) do
    x_headers = Phoenix.LiveView.get_connect_info(socket, :x_headers) || []
    peer_data = Phoenix.LiveView.get_connect_info(socket, :peer_data)

    cond do
      ip = get_header(x_headers, "x-forwarded-for") ->
        ip |> String.split(",") |> hd() |> String.trim()

      peer_data ->
        peer_data.address |> :inet.ntoa() |> to_string()

      true ->
        "unknown"
    end
  end

  defp get_header(headers, name) do
    Enum.find_value(headers, fn {header, value} ->
      if header == name, do: value
    end)
  end
end
