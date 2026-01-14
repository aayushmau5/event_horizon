defmodule EventHorizonWeb.PageController do
  use EventHorizonWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
