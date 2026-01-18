defmodule EventHorizonWeb.UsesLive.Index do
  use EventHorizonWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_path={@current_path}>
      <h1 class="font-[Handwriting] text-4xl font-bold mb-4">Uses</h1>
      <p>
        Inspired by
        <.link
          class="text-(--link-color) hover:underline"
          href="https://usesthis.com/"
          target="_blank"
        >
          usesthis.com
        </.link>
      </p>
    </Layouts.app>
    """
  end
end
