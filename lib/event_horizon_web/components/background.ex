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

          // Listen for theme changes
          this.themeHandler = () => this.applyBackgrounds();
          window.addEventListener('theme-changed', this.themeHandler);
        },

        destroyed() {
          if (this.themeHandler) {
            window.removeEventListener('theme-changed', this.themeHandler);
          }
        },

        randomTransform() {
          const skewX = -30 + Math.floor(Math.random() * 60);
          const skewY = -20 + Math.floor(Math.random() * 40);
          const scale = 0.8 + Math.random() * 0.4;
          const rotation = Math.floor(Math.random() * 360);

          return `skew(${skewX}deg, ${skewY}deg) scale(${scale}) rotate(${rotation}deg)`;
        },

        getRandomPosition() {
          const posX = 20 + Math.floor(Math.random() * 60);
          const posY = 20 + Math.floor(Math.random() * 60);
          return [posX, posY];
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

          const accentIndex = Math.floor(Math.random() * accentColors.length);
          const accentColor = accentColors[accentIndex];
          document.documentElement.style.setProperty('--accent-color', accentColor);

          const abstractBgsElements = this.el.querySelectorAll('.abstract-bg');

          if (abstractBgsElements.length >= 2) {
            const firstEl = abstractBgsElements[0];
            firstEl.style.transform = this.randomTransform();
            const [posX, posY] = this.getRandomPosition();
            firstEl.style.background = `radial-gradient(circle at ${posX}% ${posY}%, var(--accent-color) 0%, transparent ${40 + Math.floor(Math.random() * 40)}%)`;

            const secondEl = abstractBgsElements[1];
            secondEl.style.transform = this.randomTransform();
            secondEl.style.opacity = '0.6';
            secondEl.style.background = `radial-gradient(circle at ${100 - posX}% ${100 - posY}%, var(--accent-color) 0%, transparent ${40 + Math.floor(Math.random() * 20)}%)`;
          }
        }
      }
    </script>
    """
  end
end
