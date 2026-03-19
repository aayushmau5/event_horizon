defmodule EventHorizonWeb.AboutLive.Index do
  use EventHorizonWeb, :live_view

  @megu_stamps [
    %{
      id: 0,
      src: "/images/megu.jpeg"
    },
    %{
      id: 1,
      src: "/images/cat.jpg"
    },
    %{
      id: 2,
      src: "/images/megu-space.webp"
    },
    %{
      id: 3,
      src: "/images/megu-banana.webp"
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "About | Aayush Sahu")
     |> stream(:megu_stamps, @megu_stamps)}
  end
end
