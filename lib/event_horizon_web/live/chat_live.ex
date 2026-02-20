defmodule EventHorizonWeb.ChatLive do
  @moduledoc """
  Embedded LiveView that renders a floating chat overlay.
  Uses PubSub for real-time messaging between site visitors.
  """

  use EventHorizonWeb, :live_view

  alias EventHorizon.ChatBuffer

  @pubsub EventHorizon.PubSub
  @topic "chat:lobby"

  @impl true
  def mount(_params, _session, socket) do
    user_id = generate_user_id()
    username = "anon-" <> String.slice(user_id, 0, 4)

    history =
      if connected?(socket) do
        try do
          ChatBuffer.recent()
        catch
          :exit, _ -> []
        end
      else
        []
      end

    grouped_history = mark_continuations(history)
    last_sender_id = if history != [], do: List.last(history).user_id, else: nil

    socket =
      socket
      |> assign(
        open: false,
        username: username,
        user_id: user_id,
        message: "",
        unread_count: 0,
        admin: false,
        show_menu: false,
        show_login: false,
        login_error: false,
        last_sender_id: last_sender_id
      )
      |> stream(:messages, grouped_history)

    socket =
      if connected?(socket) do
        Phoenix.PubSub.subscribe(@pubsub, @topic)
        push_event(socket, "store_identity", %{user_id: user_id})
      else
        socket
      end

    {:ok, socket, layout: false}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="chat-overlay-inner" class="chat-overlay" phx-hook=".ChatClickOutside">
      <%!-- Chat toggle --%>
      <button
        id="chat-bubble-btn"
        class="chat-bubble-btn"
        style={if(@open, do: "display:none")}
        phx-click="toggle_chat"
        aria-label="Open chat"
      >
        <span class="chat-bubble-text">~/chat</span>
        <span :if={@unread_count > 0} class="chat-unread-badge">
          {min(@unread_count, 99)}
        </span>
      </button>

      <%!-- Chat panel --%>
      <div
        id="chat-panel"
        class="chat-panel"
        style={if(!@open, do: "display:none")}
        phx-hook=".ChatPanel"
      >
        <div class="chat-panel-header">
          <div class="chat-panel-title">
            <span class="chat-panel-prompt">$</span>
            <span>chat</span>
          </div>
          <div class="chat-header-actions">
            <div class="chat-menu-wrapper">
              <button
                id="chat-menu-btn"
                class="chat-close-btn"
                phx-click="toggle_menu"
                aria-label="Menu"
              >
                <.icon name="hero-ellipsis-vertical" class="w-4 h-4" />
              </button>
              <div
                id="chat-menu-dropdown"
                class="chat-menu-dropdown"
                style={if(!@show_menu, do: "display:none")}
              >
                <%= if @admin do %>
                  <button class="chat-menu-item" phx-click="sign_out">
                    Sign out
                  </button>
                <% else %>
                  <button class="chat-menu-item" phx-click="show_login">
                    Sign in as Aayush
                  </button>
                <% end %>
              </div>
            </div>
            <button
              id="chat-close-btn"
              class="chat-close-btn"
              phx-click="toggle_chat"
              aria-label="Close chat"
            >
              <.icon name="hero-x-mark" class="w-4 h-4" />
            </button>
          </div>
        </div>

        <%!-- Login form --%>
        <div
          id="chat-login"
          class="chat-login-form"
          style={if(!@show_login, do: "display:none")}
        >
          <.form for={%{}} id="chat-login-form" phx-submit="authenticate" class="chat-login-inner">
            <input
              type="password"
              name="password"
              placeholder="Password"
              class="chat-input"
              id="chat-password-field"
              autocomplete="off"
            />
            <button type="submit" class="chat-send-btn" aria-label="Sign in">
              <.icon name="hero-arrow-right" class="w-4 h-4" />
            </button>
          </.form>
          <p :if={@login_error} class="chat-login-error">Wrong password</p>
        </div>

        <div id="chat-messages" class="chat-messages" phx-update="stream">
          <div id="chat-empty" class="hidden only:flex chat-empty-state">
            <p>No messages yet. Say hi! 👋</p>
          </div>
          <div
            :for={{id, msg} <- @streams.messages}
            id={id}
            class={[
              "chat-message",
              if(msg.user_id == @user_id, do: "chat-message-self", else: "chat-message-other"),
              msg[:continuation] && "chat-message-continuation"
            ]}
          >
            <span
              :if={!msg[:continuation]}
              class={[
                "chat-message-username",
                msg[:admin] && "chat-message-admin"
              ]}
            >
              {msg.username}
            </span>
            <span class="chat-message-text">{msg.text}</span>
          </div>
        </div>

        <.form
          for={%{}}
          id="chat-form"
          phx-submit="send_message"
          phx-hook="ResetForm"
          class="chat-input-form"
          autocomplete="off"
        >
          <input
            type="text"
            name="message"
            value={@message}
            placeholder="Type a message..."
            class="chat-input"
            maxlength="280"
            id="chat-input-field"
          />
          <button type="submit" class="chat-send-btn" aria-label="Send message">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20"
              fill="currentColor"
              class="w-4 h-4"
            >
              <path d="M3.105 2.288a.75.75 0 0 0-.826.95l1.414 4.926A1.5 1.5 0 0 0 5.135 9.25h6.115a.75.75 0 0 1 0 1.5H5.135a1.5 1.5 0 0 0-1.442 1.086l-1.414 4.926a.75.75 0 0 0 .826.95 28.897 28.897 0 0 0 15.293-7.155.75.75 0 0 0 0-1.114A28.897 28.897 0 0 0 3.105 2.288Z" />
            </svg>
          </button>
        </.form>
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".ChatPanel">
      export default {
        mounted() {
          this._wasHidden = this.el.style.display === 'none';
          if (!this._wasHidden) this.scrollToBottom();
        },
        updated() {
          const isHidden = this.el.style.display === 'none';
          if (this._wasHidden && !isHidden) {
            this.scrollToBottom();
            const input = this.el.querySelector('#chat-input-field');
            if (input) requestAnimationFrame(() => input.focus());
          }
          this._wasHidden = isHidden;
          if (!isHidden) this.scrollToBottom();
        },
        scrollToBottom() {
          const messages = this.el.querySelector('#chat-messages');
          if (messages) {
            requestAnimationFrame(() => {
              messages.scrollTop = messages.scrollHeight;
            });
          }
        }
      }
    </script>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".ChatClickOutside">
      export default {
        mounted() {
          const stored = localStorage.getItem("chat_user_id");
          if (stored) {
            this.pushEvent("restore_identity", {user_id: stored});
          }
          this.handleEvent("store_identity", ({user_id}) => {
            if (!localStorage.getItem("chat_user_id")) {
              localStorage.setItem("chat_user_id", user_id);
            }
          });

          this._onClickOutside = (e) => {
            const panel = this.el.querySelector('#chat-panel');
            if (panel && !this.el.contains(e.target)) {
              this.pushEvent("close_chat", {});
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
  def handle_event("toggle_chat", _params, socket) do
    open = !socket.assigns.open
    socket = if open, do: assign(socket, unread_count: 0), else: socket
    {:noreply, assign(socket, open: open, show_menu: false, show_login: false)}
  end

  def handle_event("close_chat", _params, socket) do
    {:noreply, assign(socket, open: false, show_menu: false, show_login: false)}
  end

  def handle_event("toggle_menu", _params, socket) do
    {:noreply, assign(socket, show_menu: !socket.assigns.show_menu)}
  end

  def handle_event("show_login", _params, socket) do
    {:noreply, assign(socket, show_login: true, show_menu: false, login_error: false)}
  end

  def handle_event("authenticate", %{"password" => password}, socket) do
    configured = Application.get_env(:event_horizon, :chat_admin_password)

    if configured && configured != "" && Plug.Crypto.secure_compare(password, configured) do
      {:noreply,
       assign(socket,
         admin: true,
         username: "Aayush",
         show_login: false,
         login_error: false
       )}
    else
      {:noreply, assign(socket, login_error: true)}
    end
  end

  def handle_event("restore_identity", %{"user_id" => user_id}, socket) do
    username =
      if socket.assigns.admin,
        do: socket.assigns.username,
        else: "anon-" <> String.slice(user_id, 0, 4)

    history =
      try do
        ChatBuffer.recent()
      catch
        :exit, _ -> []
      end

    grouped_history = mark_continuations(history)
    last_sender_id = if history != [], do: List.last(history).user_id, else: nil

    {:noreply,
     socket
     |> assign(user_id: user_id, username: username, last_sender_id: last_sender_id)
     |> stream(:messages, grouped_history, reset: true)}
  end

  def handle_event("sign_out", _params, socket) do
    username = "anon-" <> String.slice(socket.assigns.user_id, 0, 4)

    {:noreply,
     assign(socket,
       admin: false,
       username: username,
       show_menu: false
     )}
  end

  def handle_event("send_message", %{"message" => text}, socket) do
    text = String.trim(text)

    if text != "" do
      msg = %{
        id: System.unique_integer([:positive]),
        user_id: socket.assigns.user_id,
        username: socket.assigns.username,
        text: text,
        admin: socket.assigns.admin,
        at: DateTime.utc_now()
      }

      try do
        ChatBuffer.push(msg)
      catch
        :exit, _ -> :ok
      end

      Phoenix.PubSub.broadcast(@pubsub, @topic, {:chat_message, msg})
    end

    {:noreply, push_event(socket, "reset-form", %{id: "chat-form"})}
  end

  @impl true
  def handle_info({:chat_message, msg}, socket) do
    continuation = msg.user_id == socket.assigns.last_sender_id
    msg = Map.put(msg, :continuation, continuation)

    socket =
      socket
      |> assign(last_sender_id: msg.user_id)
      |> stream_insert(:messages, msg)

    socket =
      if !socket.assigns.open do
        assign(socket, unread_count: socket.assigns.unread_count + 1)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp generate_user_id do
    :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false) |> String.slice(0, 8)
  end

  defp mark_continuations(messages) do
    {result, _} =
      Enum.map_reduce(messages, nil, fn msg, prev_user_id ->
        {Map.put(msg, :continuation, msg.user_id == prev_user_id), msg.user_id}
      end)

    result
  end
end
