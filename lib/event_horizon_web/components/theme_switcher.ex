defmodule EventHorizonWeb.ThemeSwitcher do
  @moduledoc """
  Theme switcher component that allows users to change the website's color theme.
  Uses a colocated JS hook for client-side theme persistence via localStorage.
  """
  use Phoenix.Component

  alias EventHorizonWeb.Themes

  @doc """
  Renders the theme switcher UI with color swatches for each available theme.
  """
  def theme_switcher(assigns) do
    themes = Themes.list_themes()
    assigns = assign(assigns, themes: themes)

    ~H"""
    <div id="theme-switcher" phx-hook=".ThemeSwitcher" phx-update="ignore">
      <p class="theme-label">Theme:</p>
      <div class="theme-grid" role="radiogroup" aria-label="Theme selection">
        <button
          :for={theme <- @themes}
          type="button"
          class="theme-swatch"
          data-theme-id={theme.id}
          role="radio"
          aria-checked="false"
          aria-label={"#{theme.name} theme"}
          title={theme.name}
        >
          <div class="color-preview" style={"background-color: #{theme.background}"}>
            <div class="accent-stripe">
              <span :for={accent <- theme.accents} style={"background-color: #{accent}"}></span>
            </div>
            <div class="checkmark">
              <svg viewBox="0 0 24 24" fill="none">
                <path d="M5 13l4 4L19 7" stroke-linecap="round" stroke-linejoin="round" />
              </svg>
            </div>
          </div>
          <span class="theme-name">{theme.name}</span>
        </button>
      </div>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".ThemeSwitcher">
      export default {
        mounted() {
          this.themes = window.__themes;
          this.swatches = this.el.querySelectorAll('.theme-swatch');

          // Load saved theme or default
          const savedTheme = localStorage.getItem('website-theme') || 'default-dark';
          this.applyTheme(savedTheme);

          // Attach click handlers
          this.swatches.forEach(swatch => {
            swatch.addEventListener('click', () => {
              const themeId = swatch.dataset.themeId;
              this.applyTheme(themeId);
              localStorage.setItem('website-theme', themeId);
            });
          });
        },

        applyTheme(themeId) {
          const theme = this.themes.find(t => t.id === themeId);
          if (!theme) return;

          // Apply CSS variables
          for (const [key, value] of Object.entries(theme.variables)) {
            document.documentElement.style.setProperty(key, value);
          }

          // Update selected state
          this.swatches.forEach(swatch => {
            const isSelected = swatch.dataset.themeId === themeId;
            swatch.classList.toggle('selected', isSelected);
            swatch.setAttribute('aria-checked', isSelected);
          });

          // Dispatch event for background to update
          window.dispatchEvent(new CustomEvent('theme-changed', { detail: { themeId } }));
        }
      }
    </script>
    """
  end
end
