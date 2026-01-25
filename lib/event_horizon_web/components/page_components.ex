defmodule EventHorizonWeb.PageComponents do
  use Phoenix.Component
  import EventHorizonWeb.CommandBar, only: [show_command_bar: 1]
  import EventHorizonWeb.ThemeSwitcher, only: [theme_switcher: 1]

  attr :current_path, :string, default: ""

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

  attr :socket, :any, default: nil

  def footer(assigns) do
    ~H"""
    <div class="footerContainer">
      <%= if @socket do %>
        <div class="site-stats-container">
          {live_render(@socket, EventHorizonWeb.SiteStatsLive, id: "site-stats", sticky: true)}
        </div>
      <% end %>
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
            <.link class="footerLink" navigate="/links">
              Links
            </.link>
          </div>
          <div class="footerLinksColumn">
            <.link class="footerLink" navigate="/cluster">
              Cluster
            </.link>
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
