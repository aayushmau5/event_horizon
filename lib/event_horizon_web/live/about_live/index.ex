defmodule EventHorizonWeb.AboutLive.Index do
  use EventHorizonWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "About | Aayush Sahu")}
  end
end
