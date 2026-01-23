defmodule EventHorizonWeb.ContactLive.Index do
  use EventHorizonWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    form = to_form(%{"email" => "", "message" => ""}, as: :contact)

    {:ok,
     socket
     |> assign(page_title: "Contact | Aayush Sahu")
     |> assign(form: form)
     |> assign(submitting: false)}
  end

  @impl true
  def handle_event("validate", %{"contact" => params}, socket) do
    form = to_form(params, as: :contact)
    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("submit", %{"contact" => params}, socket) do
    get_remote_node() |> send_message(params)

    form = to_form(%{"email" => "", "message" => ""}, as: :contact)
    {:noreply, assign(socket, form: form)}
  end

  defp get_remote_node() do
    node_prefix = System.get_env("DNS_CLUSTER_BASENAME")

    Node.list()
    |> Enum.find(fn node ->
      node_name = Atom.to_string(node)
      String.starts_with?(node_name, node_prefix)
    end)
  end

  defp send_message(node, params) do
    try do
      :erpc.call(
        node,
        Accumulator.Contact,
        :create_message,
        [%{email: Map.get(params, "email"), message: Map.get(params, "message")}],
        5_000
      )
    catch
      :error, {:erpc, :noconnection} ->
        Logger.warning("RPC failed: could not connect to node #{node}")
        {:error, :noconnection}

      :error, {:erpc, :timeout} ->
        Logger.warning("RPC timeout calling #{node}")
        {:error, :timeout}

      :error, {:erpc, reason} ->
        Logger.error("RPC error: #{inspect(reason)}")
        {:error, reason}

      :exit, {kind, exit} ->
        Logger.error("RPC exit: #{inspect(kind)} - #{inspect(exit)}")
        {:error, :remote_exit}
    else
      {:ok, _} ->
        {:ok, :success}

      {:error, _} ->
        {:error, :message_not_saved}

      {kind, reason, _stack} ->
        Logger.error("RPC raised exception: #{inspect(kind)} - #{inspect(reason)}")
        {:error, :remote_exception}
    end
  end
end
