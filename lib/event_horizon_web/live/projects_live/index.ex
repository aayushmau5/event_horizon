defmodule EventHorizonWeb.ProjectsLive.Index do
  use EventHorizonWeb, :live_view

  import EventHorizonWeb.ProjectsLive.SkillIcons

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  attr :name, :string, required: true
  attr :description, :string, required: true
  attr :image, :string, required: true
  attr :source_link, :string, required: true
  attr :demo_link, :string, required: true

  def project_box(assigns) do
    ~H"""
    <div class="project-box-container mt-8 bg-gradient-to-r from-(--theme-one) via-(--theme-two) to-(--theme-four) p-[3px] rounded-xl break-words drop-shadow-lg animate-projectLoad">
      <div class="bg-(--project-box-background) rounded-xl p-4 flex flex-col lg:flex-row">
        <div class="lg:w-[60%] lg:mr-4">
          <img src={@image} alt={@name} class="rounded-lg w-full" />
        </div>
        <div class="lg:w-full">
          <h3 class="text-xl font-bold m-0">{@name}</h3>
          <p class="text-(--projects-paragraph)">{@description}</p>
          <a href={@demo_link} class="styledLink mb-2.5 flex items-center gap-1" target="_blank" rel="noreferrer">
            <.icon name="hero-arrow-right" class="w-5 h-5" /> Demo
          </a>
          <a href={@source_link} class="styledLink flex items-center gap-1" target="_blank" rel="noreferrer">
            <.icon name="hero-arrow-right" class="w-5 h-5" /> Source
          </a>
        </div>
      </div>
    </div>
    """
  end

  slot :inner_block, required: true

  def skills_container(assigns) do
    ~H"""
    <div class="flex flex-wrap">
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :name, :string, required: true
  attr :icon, :string, required: true

  def skill_box(assigns) do
    ~H"""
    <div class="text-center p-2 text-xs lg:text-base leading-8 w-max">
      <div class="mx-auto h-[50px] w-[50px] lg:h-[90px] lg:w-[90px]">
        <.skill_icon icon={@icon} />
      </div>
      {@name}
    </div>
    """
  end
end
