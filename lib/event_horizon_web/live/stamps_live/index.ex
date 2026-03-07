defmodule EventHorizonWeb.StampsLive.Index do
  use EventHorizonWeb, :live_view

  @stamps [
    %{src: "/images/megu.jpeg", label: "Megu", year: "2024"},
    %{src: "/images/desk.webp", label: "Desk Setup", year: "2024"},
    %{src: "/images/keyboard.png", label: "Keychron K2", year: "2023"},
    %{src: "/images/desktop.png", label: "Pop OS", year: "2023"},
    %{src: "/images/editor.png", label: "VSCode", year: "2024"},
    %{src: "/images/blog/retrospective-2024/cat.jpeg", label: "Megu II", year: "2024"},
    %{src: "/images/blog/retrospective-2024/setup.jpeg", label: "Workspace", year: "2024"},
    %{src: "/images/blog/sunset.webp", label: "Sunset", year: "2023"},
    %{src: "/images/blog/plant-one.png", label: "Plant", year: "2023"},
    %{src: "/images/projects/aayushsahu.png", label: "Portfolio", year: "2022"},
    %{src: "/images/projects/battleship.png", label: "Battleship", year: "2022"},
    %{src: "/images/projects/taburei.png", label: "Taburei", year: "2023"},
    %{src: "/images/projects/blogs.png", label: "Blog App", year: "2023"},
    %{src: "/images/projects/projman.png", label: "Projman", year: "2022"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Stamps",
       stamps: @stamps
     )}
  end
end
