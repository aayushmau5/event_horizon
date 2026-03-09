defmodule EventHorizonWeb.JukeboxLive do
  @moduledoc """
  Embedded LiveView that renders a floating jukebox overlay.
  Plays ambient audio tracks (cozy vibes, lofi-chill) for visitors.

  - Cozy vibes: stackable (multiple tracks can play simultaneously)
  - Lofi chill: non-stackable (only one track at a time)
  """

  use EventHorizonWeb, :live_view

  alias EventHorizon.Presence

  @pubsub EventHorizon.PubSub
  @presence_topic "presence:jukebox"
  @base_url "https://phoenix.aayushsahu.com/uploads/9b059c42-eefc-4620-81f1-12e7e8e06c3a"

  @tracks [
    %{
      id: "rain",
      title: "Rainy Day",
      category: :cozy,
      url: "#{@base_url}/rain.mp3",
      label: "A1",
      credit_label: "freesound.org/s/828660/",
      credit_url: "https://freesound.org/s/828660/"
    },
    %{
      id: "fireplace",
      title: "Fireplace",
      category: :cozy,
      url: "#{@base_url}/fireplace.mp3",
      label: "A2",
      credit_label: "freesound.org/s/104124",
      credit_url: "https://freesound.org/s/104124"
    },
    %{
      id: "forest",
      title: "Forest Birds",
      category: :cozy,
      url: "#{@base_url}/birds.mp3",
      label: "A3",
      credit_label: "freesound.org/s/641717",
      credit_url: "https://freesound.org/s/641717"
    },
    %{
      id: "wind",
      title: "Gentle Wind",
      category: :cozy,
      url: "#{@base_url}/wind.mp3",
      label: "A4",
      credit_label: "freesound.org/s/415286",
      credit_url: "https://freesound.org/s/415286"
    },
    %{
      id: "mirrors",
      title: "Mirrors",
      category: :lofi,
      url: "#{@base_url}/mirrors.mp3",
      label: "B1",
      credit_label: "JMHBM - Mirrors · CC BY 4.0",
      credit_url: "https://freemusicarchive.org/music/beat-mekanik/single/mirrors-2/"
    },
    %{
      id: "stylish-hiphop",
      title: "Stylish Hip-Hop",
      category: :lofi,
      url: "#{@base_url}/stylish-hiphop.mp3",
      label: "B2",
      credit_label: "SoundForYou - Stylish Hip-Hop · CC BY-NC-ND 4.0",
      credit_url:
        "https://freemusicarchive.org/music/soundforyou/single/stylish-hip-hop-soulful-chill-instrumental-lofi-hip-hop/"
    },
    %{
      id: "blissful-breeze",
      title: "Blissful Breeze",
      category: :lofi,
      url: "#{@base_url}/blissful-breeze.mp3",
      label: "B3",
      credit_label: "Pumpupthemind - Blissful Breeze · CC BY-NC-ND 4.0",
      credit_url: "https://freemusicarchive.org/music/pumpupthemind/single/blissful-breeze/"
    },
    %{
      id: "road-trip",
      title: "Road Trip",
      category: :lofi,
      url: "#{@base_url}/road-trip.mp3",
      label: "B4",
      credit_label: "Purrple Cat - Road Trip · CC BY-SA 4.0",
      credit_url: "https://freemusicarchive.org/music/purrple-cat/just-relax/road-trip-2/"
    },
    %{
      id: "weather-cafe",
      title: "Trip to the Café",
      category: :lofi,
      url: "#{@base_url}/weather-cafe.mp3",
      label: "B5",
      credit_label: "AvapXia - Perfect Weather · CC BY 4.0",
      credit_url:
        "https://freemusicarchive.org/music/avapxia/summer-lofi/its-perfect-weather-for-a-trip-to-the-cafe-dont-you-think/"
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    presence_key = generate_presence_key()

    total_listeners =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(@pubsub, @presence_topic)

        Presence.track(self(), @presence_topic, presence_key, %{tracks: []})

        compute_total_listeners()
      else
        0
      end

    socket =
      assign(socket,
        open: false,
        playing: MapSet.new(),
        volume: 70,
        category: :cozy,
        tracks: @tracks,
        total_listeners: total_listeners,
        presence_key: presence_key
      )

    {:ok, socket, layout: false}
  end

  @impl true
  def render(assigns) do
    filtered =
      Enum.filter(assigns.tracks, fn t -> t.category == assigns.category end)

    assigns = assign(assigns, :filtered_tracks, filtered)

    ~H"""
    <div id="jukebox-overlay-inner" class="jukebox-overlay" phx-hook=".JukeboxClickOutside">
      <%!-- Jukebox toggle --%>
      <button
        id="jukebox-bubble-btn"
        class="jukebox-bubble-btn"
        style={if(@open, do: "display:none")}
        phx-click="toggle_jukebox"
        aria-label="Open jukebox"
      >
        <span class="jukebox-bubble-icon">♪</span>
        <span class="jukebox-bubble-text">Jukebox</span>
        <span :if={MapSet.size(@playing) > 0} class="jukebox-eq jukebox-eq-sm">
          <span class="jukebox-eq-bar"></span>
          <span class="jukebox-eq-bar"></span>
          <span class="jukebox-eq-bar"></span>
        </span>
      </button>

      <%!-- Jukebox panel --%>
      <div
        id="jukebox-panel"
        class="jukebox-panel"
        style={if(!@open, do: "display:none")}
        phx-hook=".JukeboxPanel"
      >
        <%!-- Header --%>
        <div class="jukebox-header">
          <div class="jukebox-header-title">
            <span class="jukebox-neon">♫</span>
            <span>JUKEBOX</span>
            <span :if={@total_listeners > 0} class="jukebox-listener-badge">
              {@total_listeners} listening
            </span>
          </div>
          <button
            id="jukebox-close-btn"
            class="jukebox-close-btn"
            phx-click="toggle_jukebox"
            aria-label="Close jukebox"
          >
            <.icon name="hero-x-mark" class="w-4 h-4" />
          </button>
        </div>

        <%!-- Vinyl record --%>
        <div class="jukebox-vinyl-stage">
          <div class={[
            "jukebox-vinyl",
            MapSet.size(@playing) > 0 && "jukebox-vinyl-spinning"
          ]}>
            <div class="jukebox-vinyl-label">
              <span class="jukebox-vinyl-label-text">♪</span>
            </div>
          </div>
          <%!-- Tonearm --%>
          <div class={[
            "jukebox-tonearm",
            MapSet.size(@playing) > 0 && "jukebox-tonearm-playing"
          ]}>
            <div class="jukebox-tonearm-head"></div>
          </div>
        </div>

        <%!-- Track list --%>
        <div class="jukebox-tracks">
          <button
            :for={track <- @filtered_tracks}
            id={"jukebox-track-#{track.id}"}
            class={[
              "jukebox-track",
              MapSet.member?(@playing, track.id) && "jukebox-track-active"
            ]}
            phx-click="toggle_track"
            phx-value-id={track.id}
          >
            <span class="jukebox-track-label">{track.label}</span>
            <span class="jukebox-track-title-wrap">
              <span class="jukebox-track-title">{track.title}</span>
              <a
                :if={MapSet.member?(@playing, track.id)}
                href={track.credit_url}
                target="_blank"
                rel="noopener"
                class="jukebox-track-credit-link"
                phx-click={JS.dispatch("jukebox:credit_click")}
              >
                {track.credit_label}
              </a>
            </span>
            <%= if MapSet.member?(@playing, track.id) do %>
              <span class="jukebox-eq">
                <span class="jukebox-eq-bar"></span>
                <span class="jukebox-eq-bar"></span>
                <span class="jukebox-eq-bar"></span>
              </span>
            <% else %>
              <span class="jukebox-play-icon"></span>
            <% end %>
          </button>
        </div>

        <%!-- Volume control --%>
        <div class="jukebox-volume">
          <span class="jukebox-volume-icon">VOL</span>
          <input
            id="jukebox-volume-slider"
            type="range"
            min="0"
            max="100"
            value={@volume}
            class="jukebox-volume-slider"
            name="volume"
            style={"--vol: #{@volume}%"}
          />
        </div>

        <%!-- Category tabs at the bottom --%>
        <div class="jukebox-tabs">
          <button
            id="jukebox-tab-cozy"
            class={["jukebox-tab", @category == :cozy && "jukebox-tab-active"]}
            phx-click="set_category"
            phx-value-cat="cozy"
          >
            SIDE A · Cozy
          </button>
          <button
            id="jukebox-tab-lofi"
            class={["jukebox-tab", @category == :lofi && "jukebox-tab-active"]}
            phx-click="set_category"
            phx-value-cat="lofi"
          >
            SIDE B · Lofi
          </button>
        </div>
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".JukeboxPanel">
      export default {
        mounted() {
          this._tracks = {};
          this._ctx = null;
          this._wasHidden = this.el.style.display === 'none';

          this.el.addEventListener("jukebox:credit_click", e => {
            e.stopPropagation();
          });

          const getCtx = () => {
            if (!this._ctx) this._ctx = new (window.AudioContext || window.webkitAudioContext)();
            return this._ctx;
          };

          const getVolume = () => {
            const slider = this.el.querySelector('#jukebox-volume-slider');
            return slider ? parseInt(slider.value, 10) / 100 : 0.7;
          };

          this.handleEvent("jukebox:play", ({id, url, loop}) => {
            if (this._tracks[id]) {
              this._tracks[id].audio.pause();
              this._tracks[id].source.disconnect();
              delete this._tracks[id];
            }
            const ctx = getCtx();
            const audio = new Audio(url);
            audio.crossOrigin = "anonymous";
            audio.preload = "metadata";
            audio.loop = !!loop;
            const source = ctx.createMediaElementSource(audio);
            const gain = ctx.createGain();
            gain.gain.value = getVolume();
            source.connect(gain);
            gain.connect(ctx.destination);
            if (!loop) {
              audio.addEventListener("ended", () => {
                source.disconnect();
                delete this._tracks[id];
                this.pushEvent("track_ended", {id: id});
              });
            }
            audio.play().catch(() => {});
            this._tracks[id] = {audio, source, gain};
          });

          this.handleEvent("jukebox:stop", ({id}) => {
            if (this._tracks[id]) {
              this._tracks[id].audio.pause();
              this._tracks[id].source.disconnect();
              delete this._tracks[id];
            }
          });

          this.handleEvent("jukebox:stop_all", () => {
            Object.keys(this._tracks).forEach(id => {
              this._tracks[id].audio.pause();
              this._tracks[id].source.disconnect();
              delete this._tracks[id];
            });
          });

          const slider = this.el.querySelector('#jukebox-volume-slider');
          if (slider) {
            const onVolume = () => {
              const vol = parseInt(slider.value, 10) / 100;
              slider.style.setProperty("--vol", (vol * 100) + "%");
              Object.values(this._tracks).forEach(t => t.gain.gain.value = vol);
              this.pushEvent("set_volume", {volume: parseInt(slider.value, 10)});
            };
            slider.addEventListener("input", onVolume);
            slider.addEventListener("change", onVolume);
            slider.addEventListener("touchmove", onVolume);
          }
        },
        updated() {
          this._wasHidden = this.el.style.display === 'none';
        },
        destroyed() {
          Object.values(this._tracks).forEach(t => {
            t.audio.pause();
            if (t.source) t.source.disconnect();
          });
          this._tracks = {};
          if (this._ctx) this._ctx.close();
        }
      }
    </script>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".JukeboxClickOutside">
      export default {
        mounted() {
          this._onClickOutside = (e) => {
            const panel = this.el.querySelector('#jukebox-panel');
            if (panel && panel.style.display !== 'none' && !this.el.contains(e.target)) {
              this.pushEvent("close_jukebox", {});
            }
          };
          document.addEventListener("mousedown", this._onClickOutside);
        },
        destroyed() {
          document.removeEventListener("mousedown", this._onClickOutside);
        }
      }
    </script>
    """
  end

  @impl true
  def handle_event("toggle_jukebox", _params, socket) do
    {:noreply, assign(socket, open: !socket.assigns.open)}
  end

  def handle_event("close_jukebox", _params, socket) do
    {:noreply, assign(socket, open: false)}
  end

  def handle_event("set_volume", %{"volume" => vol}, socket) do
    {:noreply, assign(socket, volume: vol)}
  end

  def handle_event("set_category", %{"cat" => cat}, socket) do
    category = String.to_existing_atom(cat)
    {:noreply, assign(socket, category: category)}
  end

  def handle_event("toggle_track", %{"id" => track_id}, socket) do
    track = Enum.find(@tracks, fn t -> t.id == track_id end)
    playing = socket.assigns.playing

    if MapSet.member?(playing, track_id) do
      socket =
        socket
        |> push_event("jukebox:stop", %{id: track_id})
        |> assign(playing: MapSet.delete(playing, track_id))
        |> update_presence()

      {:noreply, socket}
    else
      case track.category do
        :cozy ->
          socket =
            socket
            |> push_event("jukebox:play", %{
              id: track_id,
              url: track.url,
              loop: true
            })
            |> assign(playing: MapSet.put(playing, track_id))
            |> update_presence()

          {:noreply, socket}

        :lofi ->
          {:noreply, play_lofi(socket, track_id)}
      end
    end
  end

  def handle_event("track_ended", %{"id" => track_id}, socket) do
    track = Enum.find(@tracks, fn t -> t.id == track_id end)

    if track && track.category == :lofi do
      lofi_tracks = Enum.filter(@tracks, fn t -> t.category == :lofi end)
      current_idx = Enum.find_index(lofi_tracks, fn t -> t.id == track_id end)
      next_idx = rem(current_idx + 1, length(lofi_tracks))
      next_track = Enum.at(lofi_tracks, next_idx)

      {:noreply, play_lofi(socket, next_track.id)}
    else
      socket =
        socket
        |> assign(playing: MapSet.delete(socket.assigns.playing, track_id))
        |> update_presence()

      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, total_listeners: compute_total_listeners())}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp update_presence(socket) do
    tracks = MapSet.to_list(socket.assigns.playing)
    Presence.update(self(), @presence_topic, socket.assigns.presence_key, %{tracks: tracks})
    socket
  end

  defp generate_presence_key do
    :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)
  end

  defp compute_total_listeners do
    Presence.list(@presence_topic)
    |> Enum.count(fn {_key, %{metas: metas}} ->
      Enum.any?(metas, fn m -> Map.get(m, :tracks, []) != [] end)
    end)
  end

  defp play_lofi(socket, track_id) do
    track = Enum.find(@tracks, fn t -> t.id == track_id end)
    playing = socket.assigns.playing

    lofi_ids =
      @tracks
      |> Enum.filter(fn t -> t.category == :lofi end)
      |> Enum.map(fn t -> t.id end)

    socket =
      Enum.reduce(lofi_ids, socket, fn id, acc ->
        if MapSet.member?(playing, id) do
          push_event(acc, "jukebox:stop", %{id: id})
        else
          acc
        end
      end)

    new_playing =
      playing
      |> MapSet.reject(fn id -> id in lofi_ids end)
      |> MapSet.put(track_id)

    socket
    |> push_event("jukebox:play", %{
      id: track_id,
      url: track.url,
      loop: false
    })
    |> assign(playing: new_playing)
    |> update_presence()
  end
end
