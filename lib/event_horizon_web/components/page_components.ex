defmodule EventHorizonWeb.PageComponents do
  use Phoenix.Component

  import EventHorizonWeb.CoreComponents, only: [icon: 1]
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
            navigate="/work"
            class={[
              "navLink",
              if(@current_path == "/work", do: "navActive", else: "navShadow")
            ]}
          >
            Work
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
    <div class="footerContainer overflow-hidden pt-[7rem] pb-[2rem]">
      <div
        class="footerDotPattern"
        id="footer-waves"
        phx-hook="FooterWaves"
        phx-update="ignore"
        aria-hidden="true"
        data-animation="code"
      >
        <div class="footerDvdX">
          <div class="footerDvdY">
            <%!-- Logo: https://commons.wikimedia.org/wiki/File:DVD-Video_Logo.svg --%>
            <svg class="footerDvdLogo" viewBox="0 0 500 300" fill="currentColor" focusable="false">
              <path
                fill-rule="evenodd"
                clip-rule="evenodd"
                d="M469.9 212.1h-14.7l-.4 2.2h6.2l-2.2 17.3h2.6l2.3-17.3h5.7zM480.1 224.9l-3.1-12.8h-1.8l-6.7 19.5h2.2l5.4-15.1 3.1 15.1 8-15.1v15.1h2.6v-19.5h-2.6zM76.2 282.1 59 249.7H44.3l27.1 49.7h8.4l27.5-49.7H92.2zM141 275.4v24h13.3v-49.7H141zM285 299.4h36.8V291h-23v-13.3h21.7v-8.5h-21.7v-11h23v-8.5H285zM472 188.1c0-18.6-105.6-33.7-236-33.7S0 169.5 0 188.1s105.7 33.7 236 33.7 236-15 236-33.7zm-298.7.5c0-6.2 24.2-11.1 54.1-11.1s54 5 54 11-24.1 11.1-54 11.1-54-5-54-11zM392.3 249.5c-19.3 0-35 11.1-35 24.8s15.7 24.8 35 24.8 35-11 35-24.8c0-13.7-15.7-24.8-35-24.8zm0 40.6c-11.5 0-20.8-7-20.8-15.8 0-8.7 9.3-15.7 20.8-15.7s20.8 7 20.8 15.7-9.3 15.8-20.8 15.8zM214.8 249.7h-21v49.7h21s33.4 0 33.4-24.6-33.4-25-33.4-25zm-7 41.2v-32.7s26.2-1.7 26.2 16.5c0 18.1-26.1 16.2-26.1 16.2zM192 54.3a78 78 0 0 0-4-26.2h1.7L234.5 154 344.5 28h59.3S450 26.8 450 56.5s-38.4 41.2-63 41.2h-10.6l13.8-59.4h-48.3l-20.4 86.4h65.8c63 0 112.8-34.6 112.8-70.4C500 1.3 418.9.6 418.9.6h-102l-64.7 81.6L227 .6H43l-6.7 27.5h61.5c8.7.2 44 2.4 44 28.4 0 29.7-38.4 41.2-62.9 41.2H68.3L82 38.3H33.7l-20.4 86.4h65.8c63 0 112.8-34.6 112.8-70.4z"
              />
            </svg>
          </div>
        </div>
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
        <div
          id="footer-animation-controls"
          class="footerAnimationControls"
          phx-update="ignore"
          role="group"
          aria-label="Footer animation"
        >
          <span>Animation:</span>
          <button
            id="footer-animation-code"
            type="button"
            class="footerAnimationButton"
            data-footer-animation="code"
            aria-pressed="true"
          >
            <.icon name="hero-code-bracket" class="size-3.5" /> Code
          </button>
          <button
            id="footer-animation-dvd"
            type="button"
            class="footerAnimationButton"
            data-footer-animation="dvd"
            aria-pressed="false"
          >
            <.icon name="hero-play-circle" class="size-3.5" /> DVD
          </button>
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
              <.link class="footerLink" navigate="/rss.xml">
                RSS
              </.link>
              <.link class="footerLink" navigate="/resume">
                Resume
              </.link>
            </div>
          </div>
        </div>

        <div class="footerBadges">
          <img src="/images/badges/elixir.svg" alt="Powered by Elixir" width="88" height="31" />
          <img src="/images/badges/liveview.svg" alt="Phoenix LiveView" width="88" height="31" />
          <img src="/images/badges/dark-mode.gif" alt="Dark mode" width="88" height="31" />
          <img src="/images/badges/besteyes.gif" alt="Best eyes" width="88" height="31" />
          <img src="/images/badges/theoldnet_but.gif" alt="The Old Net" width="88" height="31" />
          <img src="/images/badges/button-devils.gif" alt="Devils" width="88" height="31" />
          <img src="/images/badges/built_with_love.svg" alt="Built with love" width="88" height="31" />
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
  attr :tags, :list, default: []
  attr :class, :string, default: ""

  def blog_card(assigns) do
    ~H"""
    <.link
      id={@id}
      navigate={"/blog/#{@slug}"}
      class={["blogCard", @class]}
    >
      <div class="flex gap-4">
        <p class="blogCardDate">
          <span class={["hero-calendar", "w-4 h-4"]} />
          {@date}
        </p>
        <%= if @read_time do %>
          <p class="blogCardReadTime">
            <span class={["hero-clock", "w-4 h-4"]} />
            {@read_time} min read
          </p>
        <% end %>
      </div>
      <h3>{@title}</h3>
      <%= if @description do %>
        <p class="blogCardDescription">{@description}</p>
      <% end %>
      <div :if={length(@tags) !== 0}>
        <span
          :for={tag <- @tags}
          class={[
            "blogTags",
            "text-xs opacity-50 mr-2 inline-flex items-center rounded-full px-2.5 py-0.5"
          ]}
        >
          {tag}
        </span>
      </div>
    </.link>
    """
  end
end
