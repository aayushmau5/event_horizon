defmodule EventHorizonWeb.CommandBar do
  @moduledoc """
  A command bar component similar to kbar for quick navigation and actions.
  Triggered with Cmd+K / Ctrl+K keyboard shortcut.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Renders the command bar component.

  ## Examples

      <.command_bar id="command-bar" />
  """
  attr :id, :string, default: "command-bar"

  def command_bar(assigns) do
    ~H"""
    <div
      id={@id}
      class="commandBarPositioner"
      style="display: none;"
      phx-hook=".CommandBar"
      phx-update="ignore"
    >
      <div class="commandBarAnimator" data-animator>
        <input
          type="text"
          id={"#{@id}-search"}
          class="commandBarSearch"
          placeholder="Type a command or search..."
          autocomplete="off"
          data-search-input
        />
        <div class="commandBarResultsContainer" id={"#{@id}-results"}>
          <div class="commandBarSection" data-section="actions">Actions</div>
          <.command_result
            id="cmd-go-back"
            icon="hero-arrow-left"
            title="Go Back"
            subtitle="Navigate to previous page"
            action="go-back"
            shortcut="b"
          />
          <.command_result
            id="cmd-go-forward"
            icon="hero-arrow-right"
            title="Go Forward"
            subtitle="Navigate to next page"
            action="go-forward"
            shortcut="f"
          />
          <.command_result
            id="cmd-scroll-top"
            icon="hero-arrow-up"
            title="Scroll to Top"
            subtitle="Jump to top of page"
            action="scroll-top"
            shortcut="t"
          />
          <.command_result
            id="cmd-scroll-bottom"
            icon="hero-arrow-down"
            title="Scroll to Bottom"
            subtitle="Jump to bottom of page"
            action="scroll-bottom"
            shortcut="d"
          />
          <.command_result
            id="cmd-copy-url"
            icon="hero-clipboard-document"
            title="Copy URL"
            subtitle="Copy current page URL"
            action="copy-url"
          />
          <.command_result
            id="cmd-reload"
            icon="hero-arrow-path"
            title="Reload Page"
            subtitle="Refresh the current page"
            action="reload"
          />

          <div class="commandBarSection" data-section="navigation">Navigation</div>
          <.command_result
            id="cmd-home"
            icon="hero-home"
            title="Home"
            subtitle="Go to homepage"
            href="/"
          />
          <.command_result
            id="cmd-blog"
            icon="hero-document-text"
            title="Blog"
            subtitle="Read blog posts"
            href="/blog"
          />
          <.command_result
            id="cmd-projects"
            icon="hero-code-bracket"
            title="Projects"
            subtitle="View projects"
            href="/projects"
          />
          <.command_result
            id="cmd-about"
            icon="hero-user"
            title="About"
            subtitle="Learn about me"
            href="/about"
          />
          <.command_result
            id="cmd-uses"
            icon="hero-wrench-screwdriver"
            title="Uses"
            subtitle="Tools and setup I use"
            href="/uses"
          />
          <.command_result
            id="cmd-books"
            icon="hero-book-open"
            title="Books"
            subtitle="Books I've read"
            href="/books"
          />
          <.command_result
            id="cmd-links"
            icon="hero-link"
            title="Links"
            subtitle="Social links"
            href="/links"
          />
          <.command_result
            id="cmd-contact"
            icon="hero-envelope"
            title="Contact"
            subtitle="Get in touch"
            href="/contact"
          />
        </div>
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".CommandBar">
      export default {
        mounted() {
          this.allResults = Array.from(this.el.querySelectorAll("[data-command-result]"));
          this.searchInput = this.el.querySelector("[data-search-input]");
          this.animator = this.el.querySelector("[data-animator]");
          this.selectedIndex = 0;
          this._isOpen = false;
          this._hideTimeout = null;

          this.searchInput.addEventListener("input", (e) => {
            this.filterResults(e.target.value);
          });

          this.searchInput.addEventListener("keydown", (e) => {
            this.handleKeydown(e);
          });

          this.el.addEventListener("click", (e) => {
            if (e.target === this.el) {
              e.preventDefault();
              e.stopPropagation();
              this.hide();
            }
          });

          this.allResults.forEach((result) => {
            result.addEventListener("click", (e) => {
              e.preventDefault();
              e.stopPropagation();
              this.executeCommand(result);
            });
          });

          this.handleGlobalKeydown = (e) => {
            if ((e.metaKey || e.ctrlKey) && e.key === "k") {
              e.preventDefault();
              this.toggle();
            }
            if (e.key === "Escape" && this._isOpen) {
              e.preventDefault();
              this.hide();
            }
          };

          window.addEventListener("keydown", this.handleGlobalKeydown);

          this.el.addEventListener("command-bar:show", () => {
            this.show();
          });
        },

        destroyed() {
          window.removeEventListener("keydown", this.handleGlobalKeydown);
          if (this._hideTimeout) {
            clearTimeout(this._hideTimeout);
          }
        },

        toggle() {
          if (this._isOpen) {
            this.hide();
          } else {
            this.show();
          }
        },

        show() {
          if (this._isOpen) return;
          // Cancel any pending hide animation
          if (this._hideTimeout) {
            clearTimeout(this._hideTimeout);
            this._hideTimeout = null;
          }
          this._isOpen = true;
          this.el.style.display = "flex";
          this.el.classList.remove("commandBarPositionerHide");
          this.el.classList.add("commandBarPositionerShow");
          this.searchInput.value = "";
          this.filterResults("");
          this.selectedIndex = 0;
          this.updateSelection();
          setTimeout(() => this.searchInput.focus(), 50);
        },

        hide() {
          if (!this._isOpen) return;
          this._isOpen = false;
          this.el.classList.add("commandBarPositionerHide");
          this.el.classList.remove("commandBarPositionerShow");
          this._hideTimeout = setTimeout(() => {
            this.el.style.display = "none";
            this.el.classList.remove("commandBarPositionerHide");
            this._hideTimeout = null;
          }, 200);
        },

        filterResults(query) {
          const lowerQuery = query.toLowerCase().trim();
          const sections = this.el.querySelectorAll(".commandBarSection");
          const sectionVisibility = new Map();

          sections.forEach(section => sectionVisibility.set(section, false));

          let shortcutMatchIndex = -1;

          this.allResults.forEach((result) => {
            const title = result.dataset.title.toLowerCase();
            const subtitle = result.dataset.subtitle?.toLowerCase() || "";
            const shortcut = result.dataset.shortcut?.toLowerCase();
            const hasShortcutMatch = lowerQuery && shortcut === lowerQuery;
            const hasTextMatch = title.includes(lowerQuery) || subtitle.includes(lowerQuery);

            if (hasShortcutMatch || hasTextMatch) {
              result.style.display = "flex";
              let prevSibling = result.previousElementSibling;
              while (prevSibling && !prevSibling.classList.contains("commandBarSection")) {
                prevSibling = prevSibling.previousElementSibling;
              }
              if (prevSibling) sectionVisibility.set(prevSibling, true);
            } else {
              result.style.display = "none";
            }
          });

          sections.forEach((section) => {
            section.style.display = sectionVisibility.get(section) ? "block" : "none";
          });

          if (lowerQuery) {
            const visibleResults = this.getVisibleResults();
            shortcutMatchIndex = visibleResults.findIndex(r => r.dataset.shortcut?.toLowerCase() === lowerQuery);
          }

          this.selectedIndex = shortcutMatchIndex >= 0 ? shortcutMatchIndex : 0;
          this.updateSelection();
        },

        getVisibleResults() {
          return this.allResults.filter(r => r.style.display !== "none");
        },

        handleKeydown(e) {
          const visibleResults = this.getVisibleResults();

          if (e.key === "ArrowDown") {
            e.preventDefault();
            this.selectedIndex = Math.min(this.selectedIndex + 1, visibleResults.length - 1);
            this.updateSelection();
          } else if (e.key === "ArrowUp") {
            e.preventDefault();
            this.selectedIndex = Math.max(this.selectedIndex - 1, 0);
            this.updateSelection();
          } else if (e.key === "Enter") {
            e.preventDefault();
            const selected = visibleResults[this.selectedIndex];
            if (selected) {
              this.executeCommand(selected);
            }
          }
        },

        updateSelection() {
          const visibleResults = this.getVisibleResults();
          visibleResults.forEach((result, index) => {
            if (index === this.selectedIndex) {
              result.style.background = "var(--command-bar-result-hover, #3a3a3a)";
              result.scrollIntoView({ block: "nearest", behavior: "smooth" });
            } else {
              result.style.background = "";
            }
          });
        },

        executeCommand(result) {
          const href = result.dataset.href;
          const action = result.dataset.action;
          const external = result.dataset.external === "true";

          if (href) {
            // Immediately hide without animation to prevent flicker during navigation
            this._isOpen = false;
            this.el.style.display = "none";
            if (external) {
              window.location.href = href;
            } else {
              this.liveSocket.js().navigate(href);
            }
          } else if (action === "copy-url") {
            this.hide();
            navigator.clipboard.writeText(window.location.href);
          } else if (action === "go-back") {
            this.hide();
            window.history.back();
          } else if (action === "go-forward") {
            this.hide();
            window.history.forward();
          } else if (action === "scroll-top") {
            this.hide();
            window.scrollTo({ top: 0, behavior: "smooth" });
          } else if (action === "scroll-bottom") {
            this.hide();
            window.scrollTo({ top: document.body.scrollHeight, behavior: "smooth" });
          } else if (action === "reload") {
            this.hide();
            window.location.reload();
          }
        }
      }
    </script>
    """
  end

  attr :id, :string, required: true
  attr :icon, :string, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  attr :href, :string, default: nil
  attr :action, :string, default: nil
  attr :external, :boolean, default: false
  attr :shortcut, :string, default: nil

  defp command_result(assigns) do
    ~H"""
    <div
      id={@id}
      class="commandBarResult"
      data-command-result
      data-title={@title}
      data-subtitle={@subtitle}
      data-href={@href}
      data-action={@action}
      data-external={to_string(@external)}
      data-shortcut={@shortcut}
    >
      <div class="commandBarResultItems">
        <span class="commandBarResultIcon">
          <span class={[@icon, "size-5"]} />
        </span>
        <div>
          <div>{@title}</div>
          <div class="commandBarResultSubtitle">{@subtitle}</div>
        </div>
      </div>
      <kbd :if={@shortcut} class="commandBarShortcut">{@shortcut}</kbd>
    </div>
    """
  end

  def show_command_bar(id) do
    JS.dispatch("command-bar:show", to: "##{id}")
  end
end
