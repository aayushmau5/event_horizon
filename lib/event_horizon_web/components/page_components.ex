defmodule EventHorizonWeb.PageComponents do
  use Phoenix.Component

  def nav(assigns) do
    ~H"""
    <nav class="text-(--text-color)">
      <div class="navbarContainer">
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
        </div>
      </div>
    </nav>
    """
  end

  def footer(assigns) do
    ~H"""
    <div class="footerContainer">
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
end
