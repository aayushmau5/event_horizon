defmodule EventHorizonWeb.NotFoundLive do
  use EventHorizonWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app current_path={@current_path} socket={@socket}>
      <div class="text-center mb-20 animate-fadeIn">
        <div class="w-[60%] h-auto mx-auto my-4">
          <img src="/images/cat.jpg" alt="Cat image" class="rounded-lg" />
        </div>
        <h1 class="font-[Handwriting] text-4xl font-bold">Oh no, you found the cat!</h1>
        <.link navigate="/" class="styledLink mx-auto mt-4">
          <.icon name="hero-arrow-left" class="w-6 h-6 mr-2" /> Leave the cat be
        </.link>
      </div>
    </Layouts.app>
    """
  end
end
