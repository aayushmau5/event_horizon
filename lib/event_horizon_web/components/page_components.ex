defmodule EventHorizonWeb.PageComponents do
  use Phoenix.Component
  import EventHorizonWeb.CommandBar, only: [show_command_bar: 1]
  import EventHorizonWeb.ThemeSwitcher, only: [theme_switcher: 1]

  def nav(assigns) do
    ~H"""
    <nav class="text-(--text-color)">
      <div class="navbarContainer">
        <%= if @current_path == "/" do %>
          <div class="navImageContainer">
            <img
              src="/images/index.webp"
              alt="Sunset by the mountains"
              class="navImage"
            />
          </div>
        <% end %>
        <div class="navbarLinksContainer">
          <.link
            navigate="/"
            class={[
              "styledLink",
              if(@current_path == "/", do: "navActive", else: "navShadow")
            ]}
          >
            Home
          </.link>
          <.link
            navigate="/blog"
            class={[
              "styledLink",
              if(@current_path == "/blog", do: "navActive", else: "navShadow")
            ]}
          >
            Blog
          </.link>
          <.link
            navigate="/projects"
            class={[
              "styledLink",
              if(@current_path == "/projects", do: "navActive", else: "navShadow")
            ]}
          >
            Projects
          </.link>
          <.link
            navigate="/about"
            class={[
              "styledLink",
              if(@current_path == "/about", do: "navActive", else: "navShadow")
            ]}
          >
            About
          </.link>
          <button
            type="button"
            class="kbar"
            phx-click={show_command_bar("command-bar")}
            aria-label="Open command bar"
          >
            <span class="kbarClick">⌘</span>
            <span class="kbarClick">K</span>
          </button>
        </div>
      </div>
    </nav>
    """
  end

  def footer(assigns) do
    ~H"""
    <div class="footerContainer">
      <div class="footerTop">
        <.theme_switcher />
      </div>
      <div class="footerOthers">
        <div class="footerLinks">
          <div class="footerLinksColumn">
            <.link class="footerLink" navigate="/">
              Home
            </.link>
            <.link class="footerLink" navigate="/blog">
              Blog
            </.link>
            <.link class="footerLink" navigate="/about">
              About
            </.link>
          </div>
          <div class="footerLinksColumn">
            <.link class="footerLink" navigate="/contact">
              Contact
            </.link>
            <.link class="footerLink" navigate="/links">
              Links
            </.link>
            <.link class="footerLink" navigate="/resume">
              Resume
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :header, :boolean, default: false

  def separator(assigns) do
    ~H"""
    <div class="my-4 flex justify-center">
      <svg
        class={if(@header, do: "headerSvg", else: "otherSvg")}
        width="282"
        height="12"
        viewBox="0 0 476 30"
        fill="none"
      >
        <path
          d="M4 27L17.8 8.6C20.1196 5.50721 24.5072 4.8804 27.6 7.2L48.4 22.8C51.4928 25.1196 55.8804 24.4928 58.2 21.4L67.8 8.6C70.1196 5.50721 74.5072 4.8804 77.6 7.2L98.4 22.8C101.493 25.1196 105.88 24.4928 108.2 21.4L117.8 8.6C120.12 5.50721 124.507 4.8804 127.6 7.2L148.4 22.8C151.493 25.1196 155.88 24.4928 158.2 21.4L167.8 8.6C170.12 5.50721 174.507 4.8804 177.6 7.2L198.4 22.8C201.493 25.1196 205.88 24.4928 208.2 21.4L217.8 8.6C220.12 5.50721 224.507 4.8804 227.6 7.2L248.4 22.8C251.493 25.1196 255.88 24.4928 258.2 21.4L267.8 8.6C270.12 5.50721 274.507 4.8804 277.6 7.2L298.4 22.8C301.493 25.1196 305.88 24.4928 308.2 21.4L317.8 8.6C320.12 5.50721 324.507 4.8804 327.6 7.2L348.4 22.8C351.493 25.1196 355.88 24.4928 358.2 21.4L367.8 8.6C370.12 5.50721 374.507 4.8804 377.6 7.2L398.4 22.8C401.493 25.1196 405.88 24.4928 408.2 21.4L417.8 8.6C420.12 5.50721 424.507 4.8804 427.6 7.2L448.4 22.8C451.493 25.1196 455.88 24.4928 458.2 21.4L472 3"
          stroke-linejoin="round"
          stroke-width="10"
        />
      </svg>
    </div>
    """
  end

  attr :href, :string, required: true
  slot :inner_block, required: true

  def external_link(assigns) do
    ~H"""
    <a
      class="text-(--link-color) hover:underline inline-block w-fit"
      href={@href}
      target="_blank"
      rel="noreferrer"
    >
      {render_slot(@inner_block)}
    </a>
    """
  end
end
