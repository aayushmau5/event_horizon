defmodule EventHorizonWeb.InitAssigns do
  import Phoenix.{Component, LiveView}

  def on_mount(:default, _params, _session, socket) do
    socket =
      socket
      |> attach_current_path_hook()
      |> assign(:page_title, "Aayush Sahu - Developer & Explorer")

    {:cont, socket}
  end

  def attach_current_path_hook(socket) do
    attach_hook(socket, :attach_path_hook, :handle_params, fn
      _params, url, socket ->
        url = URI.parse(url)

        socket =
          socket
          |> assign(:current_path, url.path)

        {:cont, socket}
    end)
  end
end
