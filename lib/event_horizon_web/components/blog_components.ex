defmodule EventHorizonWeb.BlogComponents do
  defmacro __using__(_opts) do
    quote do
      import EventHorizonWeb.BlogComponents
      alias EventHorizonWeb.BlogComponents.Counter
    end
  end

  use Phoenix.Component
  import EventHorizonWeb.CoreComponents

  alias Phoenix.LiveView.JS
  alias EventHorizonWeb.BlogComponents.Counter

  # ============================================================================
  # Helper Functions
  # ============================================================================

  defp format_relative_time(datetime) when is_binary(datetime) do
    case DateTime.from_iso8601(datetime) do
      {:ok, dt, _} -> format_relative_time(dt)
      _ -> datetime
    end
  end

  defp format_relative_time(%DateTime{} = datetime) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, datetime, :second)

    cond do
      diff_seconds < 60 -> "just now"
      diff_seconds < 3600 -> "#{div(diff_seconds, 60)} min ago"
      diff_seconds < 86400 -> "#{div(diff_seconds, 3600)} hours ago"
      diff_seconds < 2_592_000 -> "#{div(diff_seconds, 86400)} days ago"
      diff_seconds < 31_536_000 -> "#{div(diff_seconds, 2_592_000)} months ago"
      true -> "#{div(diff_seconds, 31_536_000)} years ago"
    end
  end

  defp format_relative_time(%NaiveDateTime{} = datetime) do
    datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> format_relative_time()
  end

  defp format_relative_time(_), do: ""

  # ============================================================================
  # Blog Index Components
  # ============================================================================

  attr :query, :string, required: true

  def blog_search_bar(assigns) do
    ~H"""
    <div class="blogSearchContainer">
      <form phx-change="search" class="blogSearchInputContainer">
        <input
          type="text"
          value={@query}
          name="query"
          class="blogSearchInput"
          placeholder="Search blog"
        />
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          class="blogSearchIcon"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z"
          />
        </svg>
      </form>
    </div>
    """
  end

  attr :active_category, :string, required: true

  def blog_category_toggle(assigns) do
    ~H"""
    <div class="blogCategoryContainer">
      <div class="blogCategoryToggleGroup">
        <button
          phx-click="select_category"
          phx-value-category="tech"
          class={[
            "blogCategoryToggleButton",
            if(@active_category == "tech", do: "blogCategoryToggleButtonActive")
          ]}
        >
          Tech
        </button>
        <button
          phx-click="select_category"
          phx-value-category="life-opinions-misc"
          class={[
            "blogCategoryToggleButton",
            if(@active_category == "life-opinions-misc", do: "blogCategoryToggleButtonActive")
          ]}
        >
          Life/Opinions/Misc
        </button>
      </div>
    </div>
    """
  end

  slot :inner_block, required: true

  def blog_tags_container(assigns) do
    ~H"""
    <div class="blogTagsContainer">
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :value, :string, required: true
  attr :is_selected, :boolean, default: false
  attr :selectable, :boolean, default: true

  def blog_tag(assigns) do
    ~H"""
    <%= if @selectable do %>
      <div
        phx-click="select_tag"
        phx-value-tag={if @value == "All", do: "", else: @value}
        class={["blogTag", if(@is_selected, do: "blogTagSelected")]}
      >
        {String.upcase(@value)}
      </div>
    <% else %>
      <div
        phx-value-tag={if @value == "All", do: "", else: @value}
        class={["blogTag", if(@is_selected, do: "blogTagSelected")]}
      >
        {String.upcase(@value)}
      </div>
    <% end %>
    """
  end

  # ============================================================================
  # Interactive Components (LiveComponents for blog posts)
  # ============================================================================

  attr :id, :string, required: true
  attr :rest, :global

  def counter(assigns) do
    ~H"""
    <.live_component module={Counter} id={@id} {@rest} />
    """
  end

  # ============================================================================
  # Table of Contents
  # ============================================================================

  attr :toc, :list, required: true

  def table_of_contents(assigns) do
    ~H"""
    <.hidden_expand summary="Table of Contents">
      <nav class="toc-nav">
        <ul class="toc-list">
          <li :for={entry <- @toc} class={"toc-item toc-level-#{entry.level}"}>
            <a href={"##{entry.id}"} class="toc-link">{entry.text}</a>
          </li>
        </ul>
      </nav>
    </.hidden_expand>
    """
  end

  # ============================================================================
  # Headings
  # ============================================================================

  attr :level, :string, required: true
  slot :inner_block, required: true

  def linked_heading(assigns) do
    ~H"""
    <div class="meow">
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ============================================================================
  # Blockquote
  # ============================================================================

  attr :rest, :global

  slot :inner_block, required: true

  def blockquote(assigns) do
    ~H"""
    <div class="p-[3px] rounded-[5px] bg-gradient-to-br from-[var(--theme-one)] via-[var(--theme-two)] to-[var(--theme-four)] my-4">
      <div class="bg-[var(--blockquote-background)] text-[var(--blockquote-color)] py-4 px-4 rounded-[inherit]">
        <blockquote {@rest}>
          {render_slot(@inner_block)}
        </blockquote>
      </div>
    </div>
    """
  end

  # ============================================================================
  # Separator
  # ============================================================================

  attr :header, :boolean, default: false

  def separator(assigns) do
    ~H"""
    <div class={if(@header, do: "my-4", else: "my-8") <> " flex justify-center"}>
      <svg
        class={if(@header, do: "headerSvg", else: "otherSvg")}
        width="282"
        height="12"
        viewBox="0 0 476 30"
        fill="none"
      >
        <path
          d="M4 27L17.8 8.6C20.1196 5.50721 24.5072 4.8804 27.6 7.2L48.4 22.8C51.4928 25.1196 55.8804 24.4928 58.2 21.4L67.8 8.6C70.1196 5.50721 74.5072 4.8804 77.6 7.2L98.4 22.8C101.493 25.1196 105.88 24.4928 108.2 21.4L117.8 8.6C120.12 5.50721 124.507 4.8804 127.6 7.2L148.4 22.8C151.493 25.1196 155.88 24.4928 158.2 21.4L167.8 8.6C170.12 5.50721 174.507 4.8804 177.6 7.2L198.4 22.8C201.493 25.1196 205.88 24.4928 208.2 21.4L217.8 8.6C220.12 5.50721 224.507 4.8804 227.6 7.2L248.4 22.8C251.493 25.1196 255.88 24.4928 258.2 21.4L267.8 8.6C270.12 5.50721 274.507 4.8804 277.6 7.2L298.4 22.8C301.493 25.1196 305.88 24.4928 308.2 21.4L317.8 8.6C320.12 5.50721 324.507 4.8804 327.6 7.2L348.4 22.8C351.493 25.1196 355.88 24.4928 358.2 21.4L367.8 8.6C370.12 5.50721 374.507 4.8804 377.6 7.2L398.4 22.8C401.493 25.1196 405.88 24.4928 408.2 21.4L417.8 8.6C420.12 5.50721 424.507 4.8804 427.6 7.2L448.4 22.8C451.493 25.1196 455.88 24.4928 458.2 21.4L472 3"
          stroke-linejoin="round"
          stroke-width="10"
        />
      </svg>
    </div>
    """
  end

  # ============================================================================
  # Image
  # ============================================================================

  attr :src, :string, required: true
  attr :alt, :string, default: ""

  def image(assigns) do
    ~H"""
    <figure class="my-6 flex justify-center">
      <img src={@src} alt={@alt} class="rounded-lg" />
    </figure>
    """
  end

  attr :src, :string, required: true
  attr :alt, :string, default: ""
  attr :caption, :string, default: ""

  def cover_image(assigns) do
    ~H"""
    <figure class="my-6 flex flex-col justify-center items-center">
      <img src={@src} alt={@alt} class="rounded-lg" />
      <div class="blogCaption">{Phoenix.HTML.raw(MDEx.to_html!(@caption))}</div>
    </figure>
    """
  end

  # ============================================================================
  # Callout
  # ============================================================================

  attr :type, :string, required: true, values: ~w(info danger)

  slot :inner_block, required: true

  def callout(assigns) do
    ~H"""
    <aside class={["callout-aside", callout_type_class(@type)]}>
      <div class={["callout-icon", callout_type_class(@type)]}>
        <.callout_icon type={@type} />
      </div>
      {render_slot(@inner_block)}
    </aside>
    """
  end

  defp callout_type_class("info"), do: "callout-info"
  defp callout_type_class("danger"), do: "callout-danger"
  defp callout_type_class(_), do: "callout-info"

  defp callout_icon(%{type: "info"} = assigns) do
    ~H"""
    <.icon name="hero-information-circle" class="w-5 h-5" />
    """
  end

  defp callout_icon(%{type: "danger"} = assigns) do
    ~H"""
    <.icon name="hero-exclamation-triangle" class="w-5 h-5" />
    """
  end

  defp callout_icon(assigns) do
    ~H"""
    """
  end

  # ============================================================================
  # BasicCard
  # ============================================================================

  slot :inner_block, required: true

  def basic_card(assigns) do
    ~H"""
    <div class="basic-card">
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ============================================================================
  # CardWithTitle
  # ============================================================================

  attr :title, :string, required: true

  slot :inner_block, required: true

  def card_with_title(assigns) do
    ~H"""
    <div class="card-with-title">
      <div class="card-title">{@title}</div>
      <div class="card-container">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  # ============================================================================
  # Code (with filename header)
  # ============================================================================

  attr :filename, :string, default: nil

  slot :inner_block, required: true

  def code(assigns) do
    ~H"""
    <div class="code-container">
      <div :if={@filename} class="code-filename-container">
        <.code_buttons />
        <div class="code-filename">
          <span class="code-icon-svg">
            <.file_icon type={get_file_type(@filename)} />
          </span>
          {@filename}
        </div>
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :to, :string, required: true
  attr :title, :string, required: true

  def redirect(assigns) do
    ~H"""
    <.link href={@to}>
      {Phoenix.HTML.raw(MDEx.to_html!(@title))}
    </.link>
    """
  end

  defp code_buttons(assigns) do
    ~H"""
    <div class="code-buttons">
      <span class="code-dot code-dot-red"></span>
      <span class="code-dot code-dot-yellow"></span>
      <span class="code-dot code-dot-green"></span>
    </div>
    """
  end

  defp get_file_type(filename) do
    filename
    |> String.split(".")
    |> List.last()
  end

  defp file_icon(%{type: "js"} = assigns) do
    ~H"""
    <svg viewBox="0 0 128 128">
      <path fill="#e9d44d" d="M1.408 1.408h125.184v125.185H1.408z"></path>
      <path
        fill="#30312f"
        d="M116.347 96.736c-.917-5.711-4.641-10.508-15.672-14.981-3.832-1.761-8.104-3.022-9.377-5.926-.452-1.69-.512-2.642-.226-3.665.821-3.32 4.784-4.355 7.925-3.403 2.023.678 3.938 2.237 5.093 4.724 5.402-3.498 5.391-3.475 9.163-5.879-1.381-2.141-2.118-3.129-3.022-4.045-3.249-3.629-7.676-5.498-14.756-5.355l-3.688.477c-3.534.893-6.902 2.748-8.877 5.235-5.926 6.724-4.236 18.492 2.975 23.335 7.104 5.332 17.54 6.545 18.873 11.531 1.297 6.104-4.486 8.08-10.234 7.378-4.236-.881-6.592-3.034-9.139-6.949-4.688 2.713-4.688 2.713-9.508 5.485 1.143 2.499 2.344 3.63 4.26 5.795 9.068 9.198 31.76 8.746 35.83-5.176.165-.478 1.261-3.666.38-8.581zM69.462 58.943H57.753l-.048 30.272c0 6.438.333 12.34-.714 14.149-1.713 3.558-6.152 3.117-8.175 2.427-2.059-1.012-3.106-2.451-4.319-4.485-.333-.584-.583-1.036-.667-1.071l-9.52 5.83c1.583 3.249 3.915 6.069 6.902 7.901 4.462 2.678 10.459 3.499 16.731 2.059 4.082-1.189 7.604-3.652 9.448-7.401 2.666-4.915 2.094-10.864 2.07-17.444.06-10.735.001-21.468.001-32.237z"
      >
      </path>
    </svg>
    """
  end

  defp file_icon(%{type: type} = assigns) when type in ["ts", "tsx"] do
    ~H"""
    <svg viewBox="0 0 128 128">
      <path fill="white" d="M22.67 47h99.67v73.67H22.67z"></path>
      <path
        fill="#2f76c4"
        d="M1.5 63.91v62.5h125v-125H1.5zm100.73-5a15.56 15.56 0 017.82 4.5 20.58 20.58 0 013 4c0 .16-5.4 3.81-8.69 5.85-.12.08-.6-.44-1.13-1.23a7.09 7.09 0 00-5.87-3.53c-3.79-.26-6.23 1.73-6.21 5a4.58 4.58 0 00.54 2.34c.83 1.73 2.38 2.76 7.24 4.86 8.95 3.85 12.78 6.39 15.16 10 2.66 4 3.25 10.46 1.45 15.24-2 5.2-6.9 8.73-13.83 9.9a38.32 38.32 0 01-9.52-.1 23 23 0 01-12.72-6.63c-1.15-1.27-3.39-4.58-3.25-4.82a9.34 9.34 0 011.15-.73L82 101l3.59-2.08.75 1.11a16.78 16.78 0 004.74 4.54c4 2.1 9.46 1.81 12.16-.62a5.43 5.43 0 00.69-6.92c-1-1.39-3-2.56-8.59-5-6.45-2.78-9.23-4.5-11.77-7.24a16.48 16.48 0 01-3.43-6.25 25 25 0 01-.22-8c1.33-6.23 6-10.58 12.82-11.87a31.66 31.66 0 019.49.26zm-29.34 5.24v5.12H56.66v46.23H45.15V69.26H28.88v-5a49.19 49.19 0 01.12-5.17C29.08 59 39 59 51 59h21.83z"
      >
      </path>
    </svg>
    """
  end

  defp file_icon(%{type: "html"} = assigns) do
    ~H"""
    <svg viewBox="0 0 128 128">
      <path fill="#dd4b25" d="M19.037 113.876L9.032 1.661h109.936l-10.016 112.198-45.019 12.48z">
      </path>
      <path fill="#dd4b25" d="M64 116.8l36.378-10.086 8.559-95.878H64z"></path>
      <path
        fill="#fff"
        d="M64 52.455H45.788L44.53 38.361H64V24.599H29.489l.33 3.692 3.382 37.927H64zm0 35.743l-.061.017-15.327-4.14-.979-10.975H33.816l1.928 21.609 28.193 7.826.063-.017z"
      >
      </path>
      <path
        fill="#fff"
        d="M63.952 52.455v13.763h16.947l-1.597 17.849-15.35 4.143v14.319l28.215-7.82.207-2.325 3.234-36.233.335-3.696h-3.708zm0-27.856v13.762h33.244l.276-3.092.628-6.978.329-3.692z"
      >
      </path>
    </svg>
    """
  end

  defp file_icon(%{type: "css"} = assigns) do
    ~H"""
    <svg viewBox="0 0 128 128">
      <path
        fill="#1a6fb4"
        d="M8.76 1l10.055 112.883 45.118 12.58 45.244-12.626L119.24 1H8.76zm89.591 25.862l-3.347 37.605.01.203-.014.467v-.004l-2.378 26.294-.262 2.336L64 101.607v.001l-.022.019-28.311-7.888L33.75 72h13.883l.985 11.054 15.386 4.17-.004.008v-.002l15.443-4.229L81.075 65H48.792l-.277-3.043-.631-7.129L47.553 51h34.749l1.264-14H30.64l-.277-3.041-.63-7.131L29.401 23h69.281l-.331 3.862z"
      >
      </path>
    </svg>
    """
  end

  defp file_icon(%{type: type} = assigns) when type in ["ex", "exs", "livemd"] do
    ~H"""
    <svg viewBox="0 0 64 64">
      <linearGradient
        id="a"
        gradientTransform="matrix(.12970797 0 0 .19997863 11.409779 -.000001)"
        gradientUnits="userSpaceOnUse"
        x1="167.51685"
        x2="160.31"
        y1="24.393208"
        y2="320.03421"
      >
        <stop offset="0" stop-color="#d9d8dc" />
        <stop offset="1" stop-color="#fff" stop-opacity=".385275" />
      </linearGradient>
      <linearGradient
        id="b"
        gradientTransform="matrix(.11420937 0 0 .22711641 11.409779 -.000001)"
        gradientUnits="userSpaceOnUse"
        x1="199.03606"
        x2="140.0712"
        y1="21.412943"
        y2="278.40781"
      >
        <stop offset="0" stop-color="#8d67af" stop-opacity=".671932" />
        <stop offset="1" stop-color="#9f8daf" />
      </linearGradient>
      <linearGradient
        id="c"
        gradientTransform="matrix(.12266694 0 0 .21145732 11.409779 -.000001)"
        gradientUnits="userSpaceOnUse"
        x1="206.42825"
        x2="206.42825"
        y1="100.91758"
        y2="294.31174"
      >
        <stop offset="0" stop-color="#26053d" stop-opacity=".761634" />
        <stop offset="1" stop-color="#b7b4b4" stop-opacity=".277683" />
      </linearGradient>
      <linearGradient
        id="d"
        gradientTransform="matrix(.18477958 0 0 .14037711 11.409779 -.000001)"
        gradientUnits="userSpaceOnUse"
        x1="23.483095"
        x2="112.93069"
        y1="171.71753"
        y2="351.72263"
      >
        <stop offset="0" stop-color="#91739f" stop-opacity=".45955" />
        <stop offset="1" stop-color="#32054f" stop-opacity=".539912" />
      </linearGradient>
      <linearGradient
        id="e"
        gradientTransform="matrix(.14183937 0 0 .18287462 11.409779 -.000001)"
        gradientUnits="userSpaceOnUse"
        x1="226.7811"
        x2="67.803513"
        y1="317.25201"
        y2="147.4131"
      >
        <stop offset="0" stop-color="#463d49" stop-opacity=".331182" />
        <stop offset="1" stop-color="#340a50" stop-opacity=".821388" />
      </linearGradient>
      <linearGradient
        id="f"
        gradientTransform="matrix(.10596912 0 0 .24477717 11.409779 -.000001)"
        gradientUnits="userSpaceOnUse"
        x1="248.0164"
        x2="200.70529"
        y1="88.755211"
        y2="255.00513"
      >
        <stop offset="0" stop-color="#715383" stop-opacity=".145239" />
        <stop offset="1" stop-color="#f4f4f4" stop-opacity=".233639" />
      </linearGradient>
      <linearGradient
        id="g"
        gradientTransform="matrix(.09173097 0 0 .28277061 11.409779 -.000001)"
        gradientUnits="userSpaceOnUse"
        x1="307.5639"
        x2="156.45103"
        y1="109.963"
        y2="81.526764"
      >
        <stop offset="0" stop-color="#a5a1a8" stop-opacity=".356091" />
        <stop offset="1" stop-color="#370c50" stop-opacity=".581975" />
      </linearGradient>
      <g fill-rule="evenodd">
        <path
          d="m34.033696.16105439c-4.649706 1.64813521-9.138214 6.45860111-13.465525 14.43139761-6.490966 11.959195-14.8743608 28.953434-3.330358 42.408733 5.340603 6.224826 14.158605 9.898679 25.730911 4.080095 9.296536-4.67432 11.882014-18.088489 8.544419-24.392035-6.884785-13.002951-13.869705-16.210096-15.740131-24.273959-1.24695-5.375909-1.826722-9.4606528-1.739316-12.25423161z"
          fill="url(#a)"
        />
        <path
          d="m34.033696-.00000095c-4.673294 1.66512615-9.161803 6.47559215-13.465525 14.43139795-6.455581 11.933709-14.8743608 28.953433-3.330358 42.408733 5.340603 6.224826 14.045121 8.236341 18.875071 4.544505 3.148725-2.40677 5.290239-4.700935 6.52406-9.534696 1.373834-5.382292.319746-12.628547-.402523-15.957361-.913952-4.212248-1.213096-8.835494-.897429-13.869735-.11123-.135513-.194345-.236927-.249347-.30424-2.514528-3.077324-4.454883-5.757778-5.314633-9.464373-1.24695-5.3759083-1.826722-9.4606522-1.739316-12.25423095z"
          fill="url(#b)"
        />
        <path
          d="m30.164134 2.0937185c-4.352812 3.440161-7.589227 9.2104935-9.709246 17.3109975-3.180029 12.150756-3.524621 23.355714-2.403077 29.873065 2.17418 12.634271 13.445838 17.430108 25.007417 11.549319 7.115151-3.619115 10.078654-11.387504 9.921651-19.81976-.162566-8.731042-17.034649-18.626155-20.022678-25.912745-1.992018-4.857728-2.923374-9.1913529-2.794067-13.0008765z"
          fill="url(#c)"
        />
        <path
          d="m41.199436 24.874043c5.220347 6.694959 6.358283 11.355459 3.413807 13.981497-4.416714 3.93906-15.217419 6.509155-21.936599 1.744215-4.479454-3.176628-6.174316-9.991206-5.084588-20.443737-1.849118 3.861723-3.412567 7.773671-4.690348 11.735849-1.27778 3.962178-1.650915 8.108529-1.119404 12.439052 1.601351 3.239683 5.494817 5.403396 11.680397 6.491139 9.278371 1.631615 18.060122.825407 23.95271-2.145065 3.928391-1.980314 5.786494-3.951651 5.574312-5.91401.141766-2.897853-.751847-5.656438-2.680832-8.275753-1.928988-2.619317-4.965472-5.823713-9.109455-9.613187z"
          fill="url(#d)"
        />
        <path
          d="m20.799251 18.189006c-.04364 4.835125 1.199603 9.431489 3.729718 13.789093 3.795174 6.536405 8.225212 12.995204 14.854367 18.348954 4.419436 3.569167 7.950747 4.722294 10.593929 3.459382-2.170994 3.88538-4.479397 5.78925-6.925211 5.711609-3.668718-.11646-8.142117-1.719788-15.309635-10.333032-4.778347-5.742163-8.047222-11.17387-9.806624-16.295121.279004-2.031676.574857-4.055285.887559-6.070826.312702-2.015542.971335-4.885561 1.975897-8.610059z"
          fill="url(#e)"
        />
        <path
          d="m32.011273 24.824412c.405511 3.938827 1.93822 10.239557 0 14.434591-1.938221 4.195036-10.890677 11.773476-8.419446 18.449432 2.47123 6.675957 8.493644 5.177168 12.271355 2.100547 3.777712-3.076623 5.799822-8.079349 6.248034-11.597523.448213-3.518171-1.072381-10.287708-1.56693-16.17596-.329698-3.9255-.106002-7.291185.671093-10.097054l-1.15758-1.456665-6.813456-2.017361c-1.092388 1.614111-1.503411 3.73411-1.23307 6.359993z"
          fill="url(#f)"
        />
        <path
          d="m34.443394 5.3148253c-2.205235.9318217-4.294586 2.7781986-6.268054 5.5391307-2.960203 4.141399-4.467906 6.623907-3.3519 14.833191.744003 5.472857 1.276531 10.50778 1.597582 15.104773l9.543032-27.726988c-.350835-1.412815-.642632-2.688766-.875391-3.8278548-.232758-1.1390887-.447848-2.446506-.645269-3.9222519z"
          fill="url(#g)"
        />
        <path
          d="m35.945755 13.009805c-2.422551 1.413992-4.299708 4.310913-5.631469 8.690763-1.331762 4.379852-2.550147 10.50277-3.655157 18.368756 1.47381-5.003069 2.451455-8.626771 2.932936-10.871105.722221-3.366501.968912-8.127131 2.886564-11.359156 1.278437-2.154684 2.434144-3.764436 3.467126-4.829258z"
          fill="#330a4c"
          fill-opacity=".316321"
        />
        <path
          d="m24.728788 59.937995c3.986659.569558 6.071303 1.075916 6.253931 1.519073.273942.664733-.504655 1.272785-2.717611.864177-1.475304-.272404-2.654077-1.06682-3.53632-2.38325z"
          fill="#fff"
        />
        <path
          d="m26.731652 5.3148253c-2.192807 2.6195801-4.092897 5.3967527-5.700271 8.3315187s-2.755892 5.124204-3.445555 6.568313c-.213753 1.077096-.318084 2.666371-.312993 4.767823.0051 2.101452.186856 4.438039.545295 7.009761.313817-5.035952 1.274508-9.924178 2.882072-14.664678 1.607565-4.740501 3.618049-8.7447464 6.031452-12.0127377z"
          fill="#ededed"
          fill-opacity=".603261"
        />
      </g>
    </svg>
    """
  end

  defp file_icon(%{type: "json"} = assigns) do
    ~H"""
    <svg viewBox="0 0 24 24" fill="none">
      <path
        stroke="#dbcd68"
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M9.5 5H9a2 2 0 0 0-2 2v2c0 1-.6 3-3 3 1 0 3 .6 3 3v2a2 2 0 0 0 2 2h.5m5-14h.5a2 2 0 0 1 2 2v2c0 1 .6 3 3 3-1 0-3 .6-3 3v2a2 2 0 0 1-2 2h-.5"
      />
    </svg>
    """
  end

  defp file_icon(assigns) do
    ~H"""
    <svg fill="#fff" viewBox="0 0 128 128">
      <path d="M 33.5 9 C 26.3 9 20.5 14.8 20.5 22 L 20.5 102 C 20.5 109.2 26.3 115 33.5 115 L 94.5 115 C 101.7 115 107.5 109.2 107.5 102 L 107.5 22 C 107.5 14.8 101.7 9 94.5 9 L 33.5 9 z M 33.5 15 L 94.5 15 C 98.4 15 101.5 18.1 101.5 22 L 101.5 102 C 101.5 105.9 98.4 109 94.5 109 L 33.5 109 C 29.6 109 26.5 105.9 26.5 102 L 26.5 22 C 26.5 18.1 29.6 15 33.5 15 z M 33.5 22 L 33.5 37 L 94.5 37 L 94.5 22 L 33.5 22 z M 37.5 51 C 35.8 51 34.5 52.3 34.5 54 C 34.5 55.7 35.8 57 37.5 57 L 88.5 57 C 90.2 57 91.5 55.7 91.5 54 C 91.5 52.3 90.2 51 88.5 51 L 37.5 51 z M 37.5 66 C 35.8 66 34.5 67.3 34.5 69 C 34.5 70.7 35.8 72 37.5 72 L 88.5 72 C 90.2 72 91.5 70.7 91.5 69 C 91.5 67.3 90.2 66 88.5 66 L 37.5 66 z M 37.5 81 C 35.8 81 34.5 82.3 34.5 84 C 34.5 85.7 35.8 87 37.5 87 L 64 87 C 65.7 87 67 85.7 67 84 C 67 82.3 65.7 81 64 81 L 37.5 81 z" />
    </svg>
    """
  end

  # ============================================================================
  # Codeblock (inline code)
  # ============================================================================

  attr :rest, :global

  slot :inner_block, required: true

  def codeblock(assigns) do
    ~H"""
    <code class="inline-codeblock" {@rest}>
      {render_slot(@inner_block)}
    </code>
    """
  end

  # ============================================================================
  # Next/Previous Articles Navigation
  # ============================================================================

  attr :adjacent, :map, required: true

  def next_prev_articles(assigns) do
    ~H"""
    <div :if={@adjacent.prev || @adjacent.next} class="next-prev-container">
      <p class="next-prev-header">Other articles</p>
      <div class="next-prev-links">
        <.article_link :if={@adjacent.prev} article={@adjacent.prev} direction={:prev} />
        <.article_link :if={@adjacent.next} article={@adjacent.next} direction={:next} />
      </div>
    </div>
    """
  end

  attr :article, :map, required: true
  attr :direction, :atom, values: [:prev, :next], required: true

  defp article_link(assigns) do
    ~H"""
    <.link
      navigate={"/blog/#{@article.slug}"}
      class={["next-prev-link", @direction == :next && "next-prev-link-next"]}
    >
      <p class={["next-prev-info", @direction == :next && "next-prev-info-next"]}>
        <%= if @direction == :prev do %>
          <.icon name="hero-arrow-left" class="w-4 h-4" /> Previous article
        <% else %>
          Next article <.icon name="hero-arrow-right" class="w-4 h-4" />
        <% end %>
      </p>
      {@article.title}
    </.link>
    """
  end

  # ============================================================================
  # Like Button
  # ============================================================================

  attr :likes, :integer, default: 0
  attr :has_liked, :boolean, default: false

  def like_button(assigns) do
    ~H"""
    <div class="mt-6 flex flex-col items-center gap-2">
      <div class="text-sm opacity-80">
        {@likes} {if @likes == 1, do: "like", else: "likes"}
      </div>
      <button
        phx-click="like"
        disabled={@has_liked}
        class="bg-transparent border-none cursor-pointer transition-all duration-200 disabled:cursor-not-allowed group"
      >
        <svg
          height="35px"
          width="35px"
          viewBox="0 0 490 490"
          class={[
            "transition-all duration-200",
            if(@has_liked,
              do: "fill-[rgb(199,73,73)]",
              else: "fill-white group-hover:fill-[rgb(199,73,73)]"
            )
          ]}
        >
          <path d="M316.554,108.336c4.553,6.922,2.629,16.223-4.296,20.774c-3.44,2.261-6.677,4.928-9.621,7.929
            c-2.938,2.995-6.825,4.497-10.715,4.497c-3.791,0-7.585-1.427-10.506-4.291c-5.917-5.801-6.009-15.298-0.207-21.212
            c4.439-4.524,9.338-8.559,14.562-11.992C302.698,99.491,312.002,101.414,316.554,108.336z M447.022,285.869
            c-1.506,1.536-148.839,151.704-148.839,151.704C283.994,452.035,265.106,460,245,460s-38.994-7.965-53.183-22.427L42.978,285.869
            c-57.304-58.406-57.304-153.441,0-211.847C70.83,45.634,107.882,30,147.31,30c36.369,0,70.72,13.304,97.69,37.648
            C271.971,43.304,306.32,30,342.689,30c39.428,0,76.481,15.634,104.332,44.021C504.326,132.428,504.326,227.463,447.022,285.869z
            M425.596,95.028C403.434,72.44,373.991,60,342.69,60c-31.301,0-60.745,12.439-82.906,35.027c-1.122,1.144-2.129,2.533-3.538,3.777
            c-7.536,6.654-16.372,6.32-22.491,0c-1.308-1.352-2.416-2.633-3.538-3.777C208.055,72.44,178.612,60,147.31,60
            c-31.301,0-60.744,12.439-82.906,35.027c-45.94,46.824-45.94,123.012,0,169.836c1.367,1.393,148.839,151.704,148.839,151.704
            C221.742,425.229,233.02,430,245,430c11.98,0,23.258-4.771,31.757-13.433l148.839-151.703l0,0
            C471.535,218.04,471.535,141.852,425.596,95.028z M404.169,116.034c-8.975-9.148-19.475-16.045-31.208-20.499
            c-7.746-2.939-16.413,0.953-19.355,8.698c-2.942,7.744,0.953,16.407,8.701,19.348c7.645,2.902,14.521,7.431,20.436,13.459
            c23.211,23.658,23.211,62.153,0,85.811l-52.648,53.661c-5.803,5.915-5.711,15.412,0.206,21.212
            c2.921,2.863,6.714,4.291,10.506,4.291c3.889,0,7.776-1.502,10.714-4.497l52.648-53.661
            C438.744,208.616,438.744,151.275,404.169,116.034z" />
        </svg>
      </button>
    </div>
    """
  end

  # ============================================================================
  # Comments Section
  # ============================================================================

  attr :comments, :list, default: []

  slot :inner_block

  def comments_section(assigns) do
    ~H"""
    <div class="mb-5">
      <h2 class="text-2xl font-bold mb-6">
        <span class="font-[Handwriting] font-bold bg-gradient-to-r from-(--theme-one) via-(--theme-two) to-(--theme-four) bg-clip-text text-transparent">
          Comments
        </span>
      </h2>
      <.comment_input />
      <.comments_list comments={@comments} />
    </div>
    """
  end

  attr :parent_id, :integer, default: nil
  attr :on_cancel, :any, default: nil

  def comment_input(assigns) do
    form_id = if assigns.parent_id, do: "reply-form-#{assigns.parent_id}", else: "comment-form"
    assigns = assign(assigns, :form_id, form_id)

    ~H"""
    <form
      id={@form_id}
      phx-submit={if @parent_id, do: "send_reply", else: "send_comment"}
      phx-hook="ResetForm"
      class={[
        "flex flex-col gap-3 bg-(--spotify-container-background) rounded-2xl transition-all duration-200 hover:bg-(--spotify-container-hover)",
        if(@parent_id, do: "p-3 mt-2", else: "p-5 my-5")
      ]}
    >
      <input :if={@parent_id} type="hidden" name="parent_id" value={@parent_id} />
      <div class="flex flex-col">
        <input
          type="text"
          name="author"
          placeholder="Your name (optional)"
          class="w-full max-w-[200px] py-3 px-4 rounded-xl border border-white/20 bg-white/10 text-inherit text-sm focus:outline-none focus:border-(--theme-one) focus:shadow-[0_0_0_2px_rgba(var(--theme-one),0.2)]"
        />
      </div>
      <div class="flex flex-col">
        <textarea
          name="content"
          placeholder={if @parent_id, do: "Write a reply...", else: "Write a comment..."}
          rows="3"
          class="w-full py-3 px-4 rounded-xl border border-white/20 bg-white/10 text-inherit text-sm resize-y min-h-20 leading-relaxed focus:outline-none focus:border-(--theme-one) focus:shadow-[0_0_0_2px_rgba(var(--theme-one),0.2)]"
        />
      </div>
      <div class="flex gap-2.5 justify-end items-center flex-wrap">
        <button
          :if={@on_cancel}
          type="button"
          phx-click={@on_cancel}
          class="py-3 px-5 rounded-xl border border-white/30 bg-transparent text-inherit cursor-pointer font-medium transition-all duration-200 text-sm whitespace-nowrap hover:bg-white/10"
        >
          Cancel
        </button>
        <button
          type="submit"
          class="py-2 px-4 text-sm rounded-lg border-none bg-gradient-to-r from-[var(--theme-one)] to-[var(--theme-two)] text-[var(--background)] cursor-pointer font-bold transition-all duration-200 whitespace-nowrap hover:translate-y-[-1px] hover:shadow-lg disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none disabled:shadow-none"
        >
          {if @parent_id, do: "Reply", else: "Send"}
        </button>
      </div>
    </form>
    """
  end

  attr :comments, :list, default: []

  def comments_list(assigns) do
    ~H"""
    <div class="flex flex-col gap-5 mb-5">
      <.comment_item :for={comment <- @comments} comment={comment} />
    </div>
    """
  end

  attr :comment, :map, required: true

  def comment_item(assigns) do
    comment_id = assigns.comment.id
    reply_form_id = "reply-form-#{comment_id}"
    reply_btn_id = "reply-btn-#{comment_id}"
    replies_container_id = "replies-#{comment_id}"
    show_replies_btn_id = "show-replies-btn-#{comment_id}"
    hide_replies_btn_id = "hide-replies-btn-#{comment_id}"

    assigns =
      assign(assigns,
        reply_form_id: reply_form_id,
        reply_btn_id: reply_btn_id,
        replies_container_id: replies_container_id,
        show_replies_btn_id: show_replies_btn_id,
        hide_replies_btn_id: hide_replies_btn_id
      )

    ~H"""
    <div class="text-base flex flex-col bg-white/[0.02] py-2.5 px-4 rounded-xl border-l-[3px] border-l-[var(--theme-one)]">
      <div class="flex items-center gap-3 mb-2.5 max-md:flex-col max-md:items-start max-md:gap-1.5">
        <span class="opacity-90 font-bold text-sm text-[var(--theme-two)]">
          {@comment.author}
        </span>
        <span class="text-xs opacity-60 ml-auto max-md:ml-0">
          {format_relative_time(@comment.inserted_at)}
        </span>
      </div>
      <div class="m-0">
        {@comment.content}
      </div>
      <div :if={@comment.replies && length(@comment.replies) > 0} class="flex items-center gap-4 mt-2">
        <button
          id={@show_replies_btn_id}
          phx-click={
            JS.hide(to: "##{@show_replies_btn_id}")
            |> JS.show(to: "##{@hide_replies_btn_id}")
            |> JS.show(to: "##{@replies_container_id}")
          }
          class="bg-transparent border-none text-[var(--theme-one)] cursor-pointer text-sm py-1 opacity-80 transition-opacity duration-200 font-medium hover:opacity-100"
        >
          Show {length(@comment.replies)} {if length(@comment.replies) == 1,
            do: "reply",
            else: "replies"}
        </button>
        <button
          id={@hide_replies_btn_id}
          phx-click={
            JS.hide(to: "##{@hide_replies_btn_id}")
            |> JS.show(to: "##{@show_replies_btn_id}")
            |> JS.hide(to: "##{@replies_container_id}")
          }
          class="hidden bg-transparent border-none text-[var(--theme-one)] cursor-pointer text-sm py-1 opacity-80 transition-opacity duration-200 font-medium hover:opacity-100"
        >
          Hide {length(@comment.replies)} {if length(@comment.replies) == 1,
            do: "reply",
            else: "replies"}
        </button>
      </div>
      <div
        :if={@comment.replies && length(@comment.replies) > 0}
        id={@replies_container_id}
        class="hidden pl-3 flex flex-col gap-4 border-l-2 border-l-white/15 mt-3"
      >
        <.reply_item :for={reply <- @comment.replies} reply={reply} />
      </div>
      <div class="mt-3">
        <button
          id={@reply_btn_id}
          phx-click={JS.hide(to: "##{@reply_btn_id}") |> JS.show(to: "##{@reply_form_id}-wrapper")}
          class="bg-transparent border-none text-white text-xs cursor-pointer font-medium p-0 m-0 hover:opacity-80"
        >
          Reply
        </button>
        <div id={"#{@reply_form_id}-wrapper"} class="hidden">
          <.comment_input
            parent_id={@comment.id}
            on_cancel={JS.show(to: "##{@reply_btn_id}") |> JS.hide(to: "##{@reply_form_id}-wrapper")}
          />
        </div>
      </div>
    </div>
    """
  end

  attr :reply, :map, required: true

  def reply_item(assigns) do
    ~H"""
    <div class="bg-white/[0.03] p-3 rounded-lg border-l-2 border-l-[var(--theme-three)] mt-2 first:mt-0">
      <div class="flex items-center gap-3 mb-1.5 max-md:flex-col max-md:items-start max-md:gap-1">
        <span class="opacity-90 font-bold text-sm text-[var(--theme-two)]">
          {@reply.author}
        </span>
        <span class="text-xs opacity-60 ml-auto max-md:ml-0">
          {format_relative_time(@reply.inserted_at)}
        </span>
      </div>
      <div class="m-0 text-sm">
        {@reply.content}
      </div>
    </div>
    """
  end

  # ============================================================================
  # HiddenExpand (details/summary)
  # ============================================================================

  attr :summary, :string, required: true

  slot :inner_block, required: true

  def hidden_expand(assigns) do
    ~H"""
    <details class="hidden-expand-details">
      <summary class="hidden-expand-summary">{@summary}</summary>
      <div class="hidden-expand-children">
        {render_slot(@inner_block)}
      </div>
    </details>
    """
  end

  # ============================================================================
  # Pre
  # ============================================================================

  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def pre(assigns) do
    ~H"""
    <pre class={["custom-pre", @class]} {@rest}>{render_slot(@inner_block)}</pre>
    """
  end

  # ============================================================================
  # StyledAnchor
  # ============================================================================

  attr :href, :string, required: true
  attr :rest, :global

  slot :inner_block, required: true

  def styled_anchor(assigns) do
    if String.starts_with?(assigns.href, "#") do
      ~H"""
      <a href={@href} class="styled-anchor" {@rest}>
        {render_slot(@inner_block)}
      </a>
      """
    else
      ~H"""
      <a href={@href} class="styled-anchor" target="_blank" rel="noreferrer noopener" {@rest}>
        {render_slot(@inner_block)}
      </a>
      """
    end
  end
end
