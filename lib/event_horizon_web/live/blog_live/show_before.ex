defmodule EventHorizonWeb.BlogLive.ShowBefore do
  use EventHorizonWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    content = """
    # Hello World
    ```elixir
    IO.puts("hello world")
    ```

    # Demo

    Hello from MDEx :wave:

    **Markdown** and **HEEx** together!

    Today is _{Calendar.strftime(DateTime.utc_now(), "%B %d, %Y")}_

    ---

    <div class="flex items-center gap-4 p-6 bg-white/10 rounded-xl my-6 not-prose">
      <div>{@count}</div>
      <button phx-click="dec" class="w-10 h-10 rounded-full bg-red-500 text-white text-xl font-bold">-</button>
      <button phx-click="inc" class="w-10 h-10 rounded-full bg-green-500 text-white text-xl font-bold">+</button>
    </div>


    ---

    Built with:
    - <.link href="https://crates.io/crates/comrak">comrak</.link>
    - <.link href="https://hex.pm/packages/mdex">MDEx</.link>

    ```elixir
    :erlang.link()
    ```
    """

    {:ok, socket |> assign(content: content) |> assign(count: 0)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 py-20 sm:px-6 lg:px-8 prose">
      {render_markdown(@content, assigns)}
    </div>
    """
  end

  def render_markdown(markdown, assigns) do
    expr =
      markdown
      |> MDEx.to_html!(extension: [phoenix_heex: true], render: [unsafe: true])
      |> EEx.compile_string(
        engine: Phoenix.LiveView.TagEngine,
        file: __ENV__.file,
        line: __ENV__.line + 1,
        caller: __ENV__,
        indentation: 0,
        source: markdown,
        tag_handler: Phoenix.LiveView.HTMLEngine
      )

    {render, _} = Code.eval_quoted(expr, [assigns: assigns], __ENV__)
    render
  end

  @impl true
  def handle_event("inc", _, socket) do
    {:noreply, assign(socket, count: socket.assigns.count + 1)}
  end

  def handle_event("dec", _, socket) do
    {:noreply, assign(socket, count: socket.assigns.count - 1)}
  end
end
