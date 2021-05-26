defmodule LitReaderWeb.Router do
  use LitReaderWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", LitReaderWeb do
    pipe_through :api

    # user
    get "/user/cur", UserController, :cur
    post "/user/auth", UserController, :auth
    post "/user/create", UserController, :create

    # read
    get "/read/get/:read_id", ReadController, :get
    get "/read/list", ReadController, :list
    post "/read/parse", ReadController, :parse
    post "/read/create", ReadController, :create
    post "/read/delete", ReadController, :delete

    # widget
    get "/widget/run/:widget_id", WidgetController, :run
    get "/widget/get/:widget_id", WidgetController, :get
    get "/widget/list/:read_id", WidgetController, :list
    post "/widget/create", WidgetController, :create
    post "/widget/delete", WidgetController, :delete
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: LitReaderWeb.Telemetry
    end
  end
end
