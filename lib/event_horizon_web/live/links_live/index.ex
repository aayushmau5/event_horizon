defmodule EventHorizonWeb.LinksLive.Index do
  use EventHorizonWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    links = [
      %{path: "/contact", name: "Contact"},
      %{path: "/books", name: "Bookshelf"},
      %{path: "/uses", name: "Uses"},
      %{path: "/about", name: "About me"},
      %{path: "/resume", name: "Resume"},
      %{path: "/rss.xml", name: "Blog RSS feed"},
      %{path: "https://phoenix.aayushsahu.com/dashboard", name: "Dashboard"},
      %{path: "https://github.com/aayushmau5", name: "Github"},
      %{path: "https://gitlab.com/aayushmau5", name: "Gitlab"},
      %{path: "https://twitter.com/aayushmau5", name: "Twitter"},
      %{path: "https://bsky.app/profile/aayushsahu.com", name: "Bluesky"},
      %{path: "https://genserver.social/aayushmau5", name: "Mastodon"},
      %{path: "https://in.linkedin.com/in/aayushmau5", name: "LinkedIn"},
      %{path: "https://open.spotify.com/user/607vbck89ne5qmel2xfmkdfoq", name: "Spotify"},
      %{path: "https://dev.to/aayushmau5", name: "DevTo"}
    ]

    {:ok,
     socket
     |> assign(links: links)
     |> assign(page_title: "Links | Aayush Sahu")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_path={@current_path} socket={@socket}>
      <div class="animate-fadeIn">
        <h1 class="font-[Handwriting] text-4xl font-bold mb-4">Links</h1>

        <ul class="flex flex-col gap-[7px]">
          <li :for={link <- @links} class="list-disc ml-4">
            <%= if String.starts_with?(link.path, "http") do %>
              <.link href={link.path} target="_blank" rel="noreferrer" class="styledLink">
                {link.name}
              </.link>
            <% else %>
              <.link navigate={link.path} class="styledLink">
                {link.name}
              </.link>
            <% end %>
          </li>
        </ul>
      </div>
    </Layouts.app>
    """
  end
end
