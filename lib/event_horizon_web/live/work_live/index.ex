defmodule EventHorizonWeb.WorkLive.Index do
  use EventHorizonWeb, :live_view

  import EventHorizonWeb.WorkLive.SkillIcons

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Work | Aayush Sahu")}
  end

  attr :name, :string, required: true
  attr :description, :string, required: true
  attr :image, :string, required: true
  attr :source_link, :string, required: true
  attr :demo_link, :string, required: true

  def project_box(assigns) do
    ~H"""
    <div class="project-card animate-projectLoad project-box-container">
      <img src={@image} alt={@name} class="project-card-image" />
      <div class="project-card-body">
        <span class="project-card-title">{@name}</span>
        <span class="project-card-desc">{@description}</span>
        <div class="project-card-links">
          <a href={@demo_link} target="_blank" rel="noreferrer" class="project-card-link">
            <.icon name="hero-arrow-top-right-on-square" class="w-3 h-3" /> Demo
          </a>
          <a href={@source_link} target="_blank" rel="noreferrer" class="project-card-link">
            <.icon name="hero-code-bracket" class="w-3 h-3" /> Source
          </a>
        </div>
      </div>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :icon, :string, required: true

  def skill_box(assigns) do
    ~H"""
    <div class="skill-card">
      <div class="skill-card-icon">
        <.skill_icon icon={@icon} />
      </div>
      <span class="skill-card-name">{@name}</span>
    </div>
    """
  end
end
