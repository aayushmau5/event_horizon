defmodule EventHorizonWeb.BlogComponents.PollComponent do
  @moduledoc """
  An interactive poll component for blog posts.

  Supports yes/no, multiple choice, and open-ended polls.

  Usage in markdown:
      <.poll_component id="my-poll" type="yes_no" question="Do you like Elixir?" />
      <.poll_component id="fav-lang" type="multiple_choice" question="Favorite?" options={["Elixir", "Rust", "Go"]} />
      <.poll_component id="feedback" type="open_ended" question="Any thoughts?" />
  """
  use EventHorizonWeb, :live_component

  alias EventHorizon.Polls

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:respondent_id, fn -> nil end)
     |> assign_new(:existing_response, fn -> nil end)
     |> assign_new(:submitted, fn -> false end)
     |> assign_new(:error, fn -> nil end)
     |> assign_new(:poll, fn -> nil end)
     |> assign_new(:options, fn -> [] end)}
  end

  def handle_event("set_respondent_id", %{"respondent_id" => rid}, socket) do
    slug = socket.assigns.id

    poll_attrs = %{
      type: socket.assigns.type,
      question: socket.assigns.question,
      options: socket.assigns.options || [],
      blog_slug: socket.assigns.blog_slug
    }

    case Polls.find_or_create_poll(slug, poll_attrs) do
      {:ok, poll} ->
        existing_response = Polls.get_response_by_poll_slug_and_respondent(slug, rid)

        {:noreply,
         assign(socket,
           respondent_id: rid,
           poll: poll,
           existing_response: existing_response
         )}

      {:error, _changeset} ->
        {:noreply, assign(socket, error: "Failed to load poll")}
    end
  end

  def handle_event("submit_choice", %{"choice" => choice}, socket) do
    case Polls.create_response(socket.assigns.poll, %{
           respondent_id: socket.assigns.respondent_id,
           choice: choice
         }) do
      {:ok, response} ->
        {:noreply, assign(socket, submitted: true, existing_response: response, error: nil)}

      {:error, _changeset} ->
        {:noreply, assign(socket, error: "Something went wrong")}
    end
  end

  def handle_event("submit_open_ended", %{"body" => body}, socket) do
    case Polls.create_response(socket.assigns.poll, %{
           respondent_id: socket.assigns.respondent_id,
           body: body
         }) do
      {:ok, response} ->
        {:noreply, assign(socket, submitted: true, existing_response: response, error: nil)}

      {:error, _changeset} ->
        {:noreply, assign(socket, error: "Something went wrong")}
    end
  end

  def render(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook=".PollRespondent"
      phx-target={@myself}
      class="my-6 p-6 rounded-2xl bg-white/[0.03] border border-white/10 backdrop-blur-sm not-prose"
    >
      <div class="flex items-center gap-2 mb-4">
        <span class="text-lg">🗳️</span>
        <h3 class="text-lg font-bold bg-gradient-to-r from-[var(--theme-one)] to-[var(--theme-two)] bg-clip-text text-transparent">
          Let me know what you think?
        </h3>
      </div>

      <p class="text-sm text-white/70 mb-5">{@question}</p>

      <%= cond do %>
        <% @respondent_id == nil -> %>
          <div class="flex flex-col gap-3">
            <div class="h-12 rounded-xl bg-white/[0.05] animate-pulse" />
            <div class="h-12 rounded-xl bg-white/[0.05] animate-pulse" />
          </div>
        <% @existing_response != nil -> %>
          <.answered_state type={@type} response={@existing_response} />
        <% true -> %>
          <.poll_form
            type={@type}
            options={@options}
            myself={@myself}
            error={@error}
          />
      <% end %>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".PollRespondent">
        export default {
          mounted() {
            const storageKey = "poll_respondent_id";
            let respondentId = localStorage.getItem(storageKey);
            if (!respondentId) {
              respondentId = crypto.randomUUID();
              localStorage.setItem(storageKey, respondentId);
            }
            this.pushEventTo(this.el, "set_respondent_id", { respondent_id: respondentId });
          }
        }
      </script>
    </div>
    """
  end

  defp answered_state(assigns) do
    ~H"""
    <div class="flex items-center gap-3 p-4 rounded-xl border border-[var(--theme-one)]/30 bg-[var(--theme-one)]/5">
      <span class="text-[var(--theme-one)] text-xl">✓</span>
      <div>
        <%= if @type == "open_ended" do %>
          <p class="text-sm text-white/70">Your response:</p>
          <p class="text-sm text-white/90 mt-1">
            {if String.length(@response.body || "") > 120,
              do: String.slice(@response.body, 0, 120) <> "…",
              else: @response.body}
          </p>
        <% else %>
          <p class="text-sm text-white/90">
            You answered: <span class="font-medium text-[var(--theme-one)]">{@response.choice}</span>
          </p>
        <% end %>
      </div>
    </div>
    """
  end

  defp poll_form(%{type: "yes_no"} = assigns) do
    ~H"""
    <div class="flex flex-col gap-3">
      <button
        :for={choice <- ["Yes", "No"]}
        phx-click="submit_choice"
        phx-value-choice={choice}
        phx-target={@myself}
        class="relative overflow-hidden rounded-xl p-4 text-left transition-all duration-300 border border-white/10 hover:border-white/30 hover:bg-white/[0.05] cursor-pointer"
      >
        <span class="font-medium text-white/90">{choice}</span>
      </button>
      <p :if={@error} class="text-sm text-red-400 mt-1">{@error}</p>
    </div>
    """
  end

  defp poll_form(%{type: "multiple_choice"} = assigns) do
    ~H"""
    <div class="flex flex-col gap-3">
      <button
        :for={option <- @options}
        phx-click="submit_choice"
        phx-value-choice={option}
        phx-target={@myself}
        class="relative overflow-hidden rounded-xl p-4 text-left transition-all duration-300 border border-white/10 hover:border-white/30 hover:bg-white/[0.05] cursor-pointer"
      >
        <span class="font-medium text-white/90">{option}</span>
      </button>
      <p :if={@error} class="text-sm text-red-400 mt-1">{@error}</p>
    </div>
    """
  end

  defp poll_form(%{type: "open_ended"} = assigns) do
    ~H"""
    <form phx-submit="submit_open_ended" phx-target={@myself} class="flex flex-col gap-3">
      <textarea
        name="body"
        rows="3"
        placeholder="Type your response..."
        class="w-full rounded-xl border border-white/10 bg-white/[0.03] p-4 text-sm text-white/90 placeholder-white/30 focus:border-[var(--theme-one)]/50 focus:outline-none focus:ring-1 focus:ring-[var(--theme-one)]/30 resize-none"
      />
      <button
        type="submit"
        class="self-end rounded-xl px-6 py-2 text-sm font-medium transition-all duration-300 border border-white/10 hover:border-white/30 hover:bg-white/[0.05] cursor-pointer text-white/90"
      >
        Submit
      </button>
      <p :if={@error} class="text-sm text-red-400 mt-1">{@error}</p>
    </form>
    """
  end
end
