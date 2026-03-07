defmodule EventHorizonWeb.StampsLive.Index do
  use EventHorizonWeb, :live_view

  @stamps [
    %{
      id: 0,
      src: "/images/megu.jpeg",
      label: "Megu",
      year: "NOV 2024",
      message: "Our little furball who rules the house."
    },
    %{
      id: 1,
      src: "/images/desk.webp",
      label: "Desk Setup",
      year: "APR 2024",
      message: "Finally got the setup looking clean."
    },
    %{
      id: 2,
      src: "/images/keyboard.png",
      label: "Keychron K2",
      year: "JUN 2023",
      message: "The gateway into the mechanical keyboard rabbit hole."
    },
    %{
      id: 3,
      src: "/images/desktop.png",
      label: "Pop OS",
      year: "2023",
      message: "Tried Pop OS for a while. Loved the tiling."
    },
    %{
      id: 4,
      src: "/images/editor.png",
      label: "VSCode",
      year: "2024",
      message: "Where most of the magic happens."
    },
    %{
      id: 5,
      src: "/images/blog/retrospective-2024/cat.jpeg",
      label: "Megu II",
      year: "2024",
      message: "She demanded a second stamp."
    },
    %{
      id: 6,
      src: "/images/blog/retrospective-2024/setup.jpeg",
      label: "Workspace",
      year: "2024",
      message: "The workspace after a few upgrades."
    },
    %{
      id: 7,
      src: "/images/blog/sunset.webp",
      label: "Sunset",
      year: "2023",
      message: "Caught this one from the balcony."
    },
    %{
      id: 8,
      src: "/images/blog/plant-one.png",
      label: "Plant",
      year: "2023",
      message: "First plant that survived more than a month."
    },
    %{
      id: 9,
      src: "/images/projects/aayushsahu.png",
      label: "Portfolio",
      year: "2022",
      message: "The very first portfolio site."
    },
    %{
      id: 10,
      src: "/images/projects/battleship.png",
      label: "Battleship",
      year: "2022",
      message: "Multiplayer battleship built for fun."
    },
    %{
      id: 11,
      src: "/images/projects/taburei.png",
      label: "Taburei",
      year: "2023",
      message: "A tab manager that actually worked."
    },
    %{
      id: 12,
      src: "/images/projects/blogs.png",
      label: "Blog App",
      year: "2023",
      message: "Where the blogging journey started."
    },
    %{
      id: 13,
      src: "/images/projects/projman.png",
      label: "Projman",
      year: "2022",
      message: "Project manager for the terminal."
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(page_title: "Stamps") |> stream(:stamps, @stamps)}
  end
end
