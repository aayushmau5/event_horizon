defmodule EventHorizonWeb.Plugs.RedirectNotFound do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    EventHorizonWeb.Router.call(conn, EventHorizonWeb.Router.init([]))
  rescue
    Phoenix.Router.NoRouteError ->
      conn
      |> Phoenix.Controller.redirect(to: "/not-found")
      |> halt()
  end
end
