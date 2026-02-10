defmodule EventHorizonWeb.Background do
  @moduledoc """
  Background component that generates dynamic abstract backgrounds
  based on the current theme colors.
  """
  use Phoenix.Component

  @doc """
  Renders the abstract background elements.
  These are positioned fixed and appear behind all content.
  """
  def abstract_background(assigns) do
    ~H"""
    <div id="abstract-bg-container" phx-hook=".AbstractBackground" phx-update="ignore">
      <div class="abstract-bg"></div>
      <div class="abstract-bg"></div>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".AbstractBackground">
      export default {
        mounted() {
          this.applyBackgrounds();

          this.themeHandler = () => this.applyBackgrounds();
          window.addEventListener('theme-changed', this.themeHandler);
        },

        destroyed() {
          if (this.themeHandler) {
            window.removeEventListener('theme-changed', this.themeHandler);
          }
        },

        addTransparency(hex, alpha) {
          if (!hex || hex.trim() === '') return 'rgba(0, 0, 0, 0)';

          hex = hex.trim();
          if (hex.startsWith('#')) {
            hex = hex.slice(1);
          }

          const r = parseInt(hex.substring(0, 2), 16);
          const g = parseInt(hex.substring(2, 4), 16);
          const b = parseInt(hex.substring(4, 6), 16);

          alpha = Math.min(1, Math.max(0, alpha));

          return `rgba(${r}, ${g}, ${b}, ${alpha})`;
        },

        applyBackgrounds() {
          const bg = window.__bgRandom || {
            posX: 50, posY: 50, accentIndex: 0,
          };

          const style = window.getComputedStyle(document.documentElement);
          const accentColor1 = style.getPropertyValue('--theme-one').trim();
          const accentColor2 = style.getPropertyValue('--theme-two').trim();
          const accentColor3 = style.getPropertyValue('--theme-three').trim();
          const accentColor4 = style.getPropertyValue('--theme-four').trim();

          const accentColors = [
            this.addTransparency(accentColor1, 0.3),
            this.addTransparency(accentColor2, 0.3),
            this.addTransparency(accentColor3, 0.3),
            this.addTransparency(accentColor4, 0.3),
          ];

          const accentColor = accentColors[bg.accentIndex];
          document.documentElement.style.setProperty('--accent-color', accentColor);

          const abstractBgsElements = this.el.querySelectorAll('.abstract-bg');

          if (abstractBgsElements.length >= 2) {
            const firstEl = abstractBgsElements[0];
            firstEl.style.background = `radial-gradient(ellipse 80% 80% at ${bg.posX}% ${bg.posY}%, var(--accent-color) 0%, transparent 70%)`;

            const secondEl = abstractBgsElements[1];
            secondEl.style.opacity = '0.6';
            secondEl.style.background = `radial-gradient(ellipse 80% 80% at ${100 - bg.posX}% ${100 - bg.posY}%, var(--accent-color) 0%, transparent 70%)`;
          }
        }
      }
    </script>
    """
  end
end
