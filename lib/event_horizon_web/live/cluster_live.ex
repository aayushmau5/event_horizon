defmodule EventHorizonWeb.ClusterLive do
  use EventHorizonWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      EventHorizon.Latency.subscribe()
    end

    latencies = EventHorizon.Latency.get_latencies()

    {:ok,
     socket
     |> assign(page_title: "Cluster | Aayush Sahu")
     |> assign(latencies: latencies)}
  end

  @impl true
  def handle_event("ping", _params, socket) do
    {:noreply, push_event(socket, "pong", %{})}
  end

  @impl true
  def handle_info({:latency_updated, latencies}, socket) do
    {:noreply, assign(socket, latencies: latencies)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_path={@current_path} socket={@socket}>
      <h1 class="font-bold font-[Handwriting] mb-4 text-[2.5rem]">Cluster</h1>
      <p class="text-(--font-color)">
        This app is hosted on fly.io. I have two other elixir apps hosted on fly.io at different regions.
      </p>
      <p class="text-(--font-color)">
        fly.io provides private networking between apps cross-region. For fun, I clustered my app with the other two applications.
      </p>
      <p class="text-(--font-color)">
        What you see is the latency between these clusters along with your latency with this app ;)
      </p>

      <div class="rounded-xl p-6">
        <svg viewBox="0 0 400 420" class="w-full max-w-lg mx-auto">
          <defs>
            <marker
              id="arrowhead"
              markerWidth="10"
              markerHeight="7"
              refX="9"
              refY="3.5"
              orient="auto"
            >
              <polygon points="0 0, 10 3.5, 0 7" fill="#71717a" />
            </marker>
          </defs>
          <%!-- Nodes --%>
          <%!-- You (Client) - Top --%>
          <g id="client-ping" phx-hook=".ClientPing">
            <rect
              x="150"
              y="10"
              width="100"
              height="50"
              rx="12"
              fill="#1e1b4b"
              stroke="#6366f1"
              stroke-width="2"
            />
            <text x="200" y="40" text-anchor="middle" fill="#fafafa" font-size="14" font-weight="600">
              You
            </text>
          </g>
          <%!-- EH - Middle --%>
          <g>
            <rect
              x="150"
              y="120"
              width="100"
              height="60"
              rx="12"
              fill="#18181b"
              stroke="#3f3f46"
              stroke-width="2"
            />
            <text x="200" y="145" text-anchor="middle" fill="#fafafa" font-size="14" font-weight="600">
              Website
            </text>
            <text x="200" y="165" text-anchor="middle" fill="#a1a1aa" font-size="10">
              Amsterdam
            </text>
          </g>
          <%!-- PHX - Bottom Right --%>
          <g>
            <rect
              x="280"
              y="310"
              width="100"
              height="60"
              rx="12"
              fill="#18181b"
              stroke="#3f3f46"
              stroke-width="2"
            />
            <text x="330" y="335" text-anchor="middle" fill="#fafafa" font-size="14" font-weight="600">
              Accumulator
            </text>
            <text x="330" y="355" text-anchor="middle" fill="#a1a1aa" font-size="10">
              Paris
            </text>
          </g>
          <%!-- BSH - Bottom Left --%>
          <g>
            <rect
              x="20"
              y="310"
              width="100"
              height="60"
              rx="12"
              fill="#18181b"
              stroke="#3f3f46"
              stroke-width="2"
            />
            <text x="70" y="335" text-anchor="middle" fill="#fafafa" font-size="14" font-weight="600">
              Battleship
            </text>
            <text x="70" y="355" text-anchor="middle" fill="#a1a1aa" font-size="10">
              Mumbai
            </text>
          </g>
          <%!-- Edges with latency labels --%>
          <%!-- You → EH --%>
          <line
            x1="200"
            y1="60"
            x2="200"
            y2="120"
            stroke="#6366f1"
            stroke-width="2"
            marker-end="url(#arrowhead)"
          />
          <g id="client-rtt-container" phx-update="ignore">
            <text
              id="client-rtt-label"
              x="230"
              y="95"
              text-anchor="start"
              fill="#71717a"
              font-size="12"
            >
              —
            </text>
          </g>
          <%!-- EH → PHX --%>
          <line
            x1="230"
            y1="180"
            x2="300"
            y2="310"
            stroke="#71717a"
            stroke-width="2"
            marker-end="url(#arrowhead)"
          />
          <text
            x="280"
            y="235"
            text-anchor="middle"
            fill={latency_color(@latencies.eh_to_phx)}
            font-size="12"
          >
            {format_latency(@latencies.eh_to_phx)}
          </text>
          <%!-- EH → BSH --%>
          <line
            x1="170"
            y1="180"
            x2="100"
            y2="310"
            stroke="#71717a"
            stroke-width="2"
            marker-end="url(#arrowhead)"
          />
          <text
            x="120"
            y="235"
            text-anchor="middle"
            fill={latency_color(@latencies.eh_to_bsh)}
            font-size="12"
          >
            {format_latency(@latencies.eh_to_bsh)}
          </text>
          <%!-- PHX → BSH --%>
          <line
            x1="280"
            y1="340"
            x2="120"
            y2="340"
            stroke="#71717a"
            stroke-width="2"
            marker-end="url(#arrowhead)"
          />
          <text
            x="200"
            y="330"
            text-anchor="middle"
            fill={latency_color(@latencies.phx_to_bsh)}
            font-size="12"
          >
            {format_latency(@latencies.phx_to_bsh)}
          </text>
        </svg>
      </div>

      <div class="mt-6 text-zinc-500 text-sm text-center">
        Latency updates every ~750ms
      </div>
    </Layouts.app>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".ClientPing">
      export default {
        mounted() {
          this.label = document.getElementById("client-rtt-label")
          this.handleEvent("pong", () => {
            const rtt = Date.now() - this.startTime
            this.updateLabel(rtt)
            this.timer = setTimeout(() => this.ping(), 5000)
          })
          this.ping()
        },
        reconnected() {
          clearTimeout(this.timer)
          this.ping()
        },
        destroyed() {
          clearTimeout(this.timer)
        },
        ping() {
          this.startTime = Date.now()
          this.pushEvent("ping", {})
        },
        updateLabel(rtt) {
          if (!this.label) return
          this.label.textContent = rtt + " ms"
          if (rtt < 50) {
            this.label.setAttribute("fill", "#22c55e")
          } else if (rtt < 150) {
            this.label.setAttribute("fill", "#eab308")
          } else {
            this.label.setAttribute("fill", "#ef4444")
          }
        }
      }
    </script>
    """
  end

  defp format_latency({:ok, ms}), do: "#{ms} ms"
  defp format_latency({:error, :not_connected}), do: "disconnected"
  defp format_latency({:error, _}), do: "timeout"
  defp format_latency(nil), do: "—"

  defp latency_color({:ok, ms}) when ms < 50, do: "#22c55e"
  defp latency_color({:ok, ms}) when ms < 150, do: "#eab308"
  defp latency_color({:ok, _}), do: "#ef4444"
  defp latency_color(_), do: "#71717a"
end
