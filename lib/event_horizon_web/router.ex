defmodule EventHorizonWeb.Router do
  use EventHorizonWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EventHorizonWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", EventHorizonWeb do
    pipe_through :browser

    get "/resume", ResumeController, :show

    # Embedded LiveView for site stats (no on_mount hooks)
    live_session :embedded do
      live "/live/site-stats", SiteStatsLive
    end

    live_session :default, on_mount: EventHorizonWeb.InitAssigns do
      live "/", HomeLive.Index, :index
      live "/blog", BlogLive.Index, :index
      live "/blog/:slug", BlogLive.Show, :show
      live "/projects", ProjectsLive.Index, :index
      live "/about", AboutLive.Index, :index
      live "/links", LinksLive.Index, :index
      live "/contact", ContactLive.Index, :index
      live "/books", BooksLive.Index, :index
      live "/uses", UsesLive.Index, :index
      live "/cluster", ClusterLive, :index
      live "/not-found", NotFoundLive, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", EventHorizonWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:event_horizon, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: EventHorizonWeb.Telemetry
    end
  end
end
