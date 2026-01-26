defmodule EventHorizonWeb.BlogComponents.Poll do
  @moduledoc """
  An Interactive poll component for blog posts.
  Specifically made for "nextjs-to-phoenix" blog.

  ## Usage

      <%= live_render(@socket, EventHorizonWeb.BlogComponents.Poll, id: "poll-live") %>

  ## Important

  When using `live_render` in markdown, avoid using an `id` that matches any
  heading anchor (e.g., `# Poll` generates `id="poll"`). This causes the LiveView
  to be incorrectly nested inside the heading's anchor tag.
  """
  use EventHorizonWeb, :live_view

  alias EventHorizonWeb.BlogComponents.PollMockVoter

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(EventHorizon.PubSub, PollMockVoter.topic())
    end

    results = [
      %{name: "Phoenix LiveView", key: "phx_lv", votes: 0},
      %{name: "NextJS", key: "next", votes: 0}
    ]

    total_votes = Enum.reduce(results, 0, fn opt, acc -> acc + opt.votes end)

    {:ok, assign(socket, results: results, voted_for: nil, total_votes: total_votes)}
  end

  @impl true
  def handle_event("vote", %{"key" => key}, socket) do
    if socket.assigns.voted_for do
      {:noreply, socket}
    else
      results =
        Enum.map(socket.assigns.results, fn option ->
          if option.key == key do
            %{option | votes: option.votes + 1}
          else
            option
          end
        end)

      total_votes = Enum.reduce(results, 0, fn opt, acc -> acc + opt.votes end)

      # TODO: Broadcast vote via PubSub for other users
      # Phoenix.PubSub.broadcast(EventHorizon.PubSub, PollMockVoter.topic(), {:poll_vote, key})

      {:noreply, assign(socket, results: results, voted_for: key, total_votes: total_votes)}
    end
  end

  @impl true
  def handle_info({:poll_vote, key}, socket) do
    results =
      Enum.map(socket.assigns.results, fn option ->
        if option.key == key do
          %{option | votes: option.votes + 1}
        else
          option
        end
      end)

    total_votes = Enum.reduce(results, 0, fn opt, acc -> acc + opt.votes end)

    {:noreply, assign(socket, results: results, total_votes: total_votes)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="my-6 p-6 rounded-2xl bg-white/[0.03] border border-white/10 backdrop-blur-sm">
      <div class="flex items-center gap-2 mb-4">
        <span class="text-lg">🗳️</span>
        <h3 class="text-lg font-bold bg-gradient-to-r from-[var(--theme-one)] to-[var(--theme-two)] bg-clip-text text-transparent">
          Quick Poll
        </h3>
      </div>

      <p class="text-sm text-white/70 mb-5">
        Which framework do you prefer?
      </p>

      <div class="flex flex-col gap-3">
        <.poll_option
          :for={{option, index} <- Enum.with_index(@results)}
          option={option}
          index={index}
          voted_for={@voted_for}
          total_votes={@total_votes}
        />
      </div>

      <div class="mt-4 text-xs text-white/50 text-center">
        {if @voted_for, do: "Thanks for voting!", else: "Click to vote"}
        <span class="mx-2">•</span>
        {@total_votes} {if @total_votes == 1, do: "vote", else: "votes"}
      </div>
    </div>
    """
  end

  @colors ["bg-[#21daa2]", "bg-[#36c3ef]"]

  defp poll_option(assigns) do
    percentage =
      if assigns.total_votes > 0 do
        round(assigns.option.votes / assigns.total_votes * 100)
      else
        0
      end

    is_selected = assigns.voted_for == assigns.option.key
    has_voted = assigns.voted_for != nil
    color = Enum.at(@colors, rem(assigns.index, length(@colors)))

    assigns =
      assigns
      |> assign(:percentage, percentage)
      |> assign(:is_selected, is_selected)
      |> assign(:has_voted, has_voted)
      |> assign(:color, color)

    ~H"""
    <button
      phx-click="vote"
      phx-value-key={@option.key}
      disabled={@has_voted}
      class={[
        "relative overflow-hidden rounded-xl p-4 text-left transition-all duration-300",
        "border bg-white/[0.02]",
        !@has_voted && "border-white/10 hover:border-white/30 hover:bg-white/[0.05] cursor-pointer",
        @has_voted && !@is_selected && "border-white/10 cursor-default",
        @is_selected && "border-[var(--theme-one)] cursor-default"
      ]}
    >
      <div
        class={["absolute inset-y-0 left-0 opacity-20", @color]}
        style={"width: #{@percentage}%; transition: width 0.5s ease-out;"}
      />

      <div class="relative flex items-center justify-between">
        <span class={["font-medium", @is_selected && "text-[var(--theme-one)]", !@is_selected && "text-white/90"]}>
          {if @is_selected, do: "✓ ", else: ""}{@option.name}
        </span>
        <span class="text-sm font-bold text-white/80">
          {@percentage}%
        </span>
      </div>

      <div class="relative mt-1 text-xs text-white/50">
        {@option.votes} {if @option.votes == 1, do: "vote", else: "votes"}
      </div>
    </button>
    """
  end
end
