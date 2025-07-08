defmodule EnkiroWeb.Router do
  use EnkiroWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EnkiroWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # This pipeline verifies the JWT and loads the user for protected routes.
  pipeline :api_protected do
    plug Guardian.Plug.VerifyHeader,
      scheme: "Bearer",
      module: Enkiro.Guardian,
      error_handler: Enkiro.AuthErrorHandler

    plug Guardian.Plug.EnsureAuthenticated,
      module: Enkiro.Guardian,
      error_handler: Enkiro.AuthErrorHandler

    plug Guardian.Plug.LoadResource, allow_blank: false, module: Enkiro.Guardian
  end

  scope "/", EnkiroWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", EnkiroWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:enkiro, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: EnkiroWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## API routes

  # --- Public Routes ---
  # Login remains public. It's how you get a token.
  scope "/api", EnkiroWeb do
    pipe_through :api

    post "/users/login", UserSessionController, :create
  end

  # --- Protected Routes ---
  # Any route in this scope will require a valid JWT.
  scope "/api", EnkiroWeb do
    pipe_through [:api, :api_protected]

    # Protected routes that require authentication
    delete "/users/logout", UserSessionController, :delete
    get "/users/profile", UserProfileController, :show
  end
end
