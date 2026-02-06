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
        <div class="navbarLinksContainer" id="navbar-links" phx-hook=".NavHover">
          <div class="navHoverPill"></div>
          <.link
            navigate="/"
            class={[
              "navLink",
              if(@current_path == "/", do: "navActive", else: "navShadow")
            ]}
          >
            Home
          </.link>
          <.link
            navigate="/blog"
            class={[
              "navLink",
              if(@current_path == "/blog", do: "navActive", else: "navShadow")
            ]}
          >
            Blog
          </.link>
          <.link
            navigate="/projects"
            class={[
              "navLink",
              if(@current_path == "/projects", do: "navActive", else: "navShadow")
            ]}
          >
            Projects
          </.link>
          <.link
            navigate="/about"
            class={[
              "navLink",
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
    <script :type={Phoenix.LiveView.ColocatedHook} name=".NavHover">
      export default {
        mounted() {
          this.pill = this.el.querySelector('.navHoverPill');
          this.links = this.el.querySelectorAll('.navLink');
          this.enabled = false;

          this.links.forEach(link => {
            link.addEventListener('mouseenter', () => {
              if (this.enabled) this.movePill(link);
            });
          });

          this.el.addEventListener('mousemove', () => {
            this.enabled = true;
          }, { once: true });

          this.el.addEventListener('mouseleave', () => this.hidePill());
        },

        movePill(link) {
          const containerRect = this.el.getBoundingClientRect();
          const linkRect = link.getBoundingClientRect();
          const padding = 8;

          this.pill.style.opacity = '1';
          this.pill.style.width = `${linkRect.width + padding * 2}px`;
          this.pill.style.height = `${linkRect.height + padding}px`;
          this.pill.style.left = `${linkRect.left - containerRect.left - padding}px`;
          this.pill.style.top = `${linkRect.top - containerRect.top - padding / 2}px`;
        },

        hidePill() {
          this.pill.style.opacity = '0';
        }
      }
    </script>
    """
  end

  attr :socket, :any, default: nil

  def footer(assigns) do
    ~H"""
    <div class="footerContainer overflow-hidden pt-[7rem]">
      <div class="footerDotPattern" id="footer-waves" phx-hook="FooterWaves" phx-update="ignore">
      </div>
      <div>
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

  attr :id, :string, required: true
  attr :slug, :string, required: true
  attr :title, :string, required: true
  attr :date, :string, required: true
  attr :description, :string, default: nil
  attr :read_time, :string, default: nil
  attr :class, :string, default: ""

  def blog_card(assigns) do
    ~H"""
    <.link
      id={@id}
      navigate={"/blog/#{@slug}"}
      class={["blogCard", @class]}
      phx-hook="Tilt"
    >
      <p class="blogCardDate">{@date}</p>
      <h3>{@title}</h3>
      <%= if @description do %>
        <p class="blogCardDescription">{@description}</p>
      <% end %>
      <%= if @read_time do %>
        <p class="blogCardReadTime">{@read_time} min read</p>
      <% end %>
    </.link>
    """
  end
end
