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

  pipeline :api_refresh do
    plug Guardian.Plug.Pipeline,
      module: Enkiro.Guardian,
      error_handler: Enkiro.AuthErrorHandler,
      key: :default

    plug Guardian.Plug.VerifyHeader,
      scheme: :none,
      refresh_from_cookie: [
        key: "enkiro_refresh",
        # The "typ" of the token in the cookie.
        exchange_from: "refresh",
        # The "typ" of the new token to create.
        exchange_to: "access",
        # Set a TTL for the new access token.
        ttl: {1, :hour}
      ]
  end

  pipeline :api_protected do
    plug Guardian.Plug.VerifyHeader,
      scheme: "Bearer",
      claims: %{"typ" => "access"},
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

  scope "/api/v1", EnkiroWeb.V1 do
    # All routes in this scope will go through the base :api pipeline
    pipe_through :api

    # --- Public Routes ---
    post "/users/login", UserSessionController, :create
    post "/users/register", UserRegisterController, :create

    # --- Special Refresh Route ---
    # This route uses its own specific pipeline
    scope "/" do
      pipe_through :api_refresh
      post "/users/refresh", UserSessionController, :refresh
    end

    # --- Protected Routes ---
    # These routes require the standard :api_protected pipeline
    scope "/" do
      pipe_through :api_protected

      get "/users/me", UserProfileController, :show_me
      put "/users/me", UserProfileController, :update_me

      delete "/users/logout", UserSessionController, :delete
      # Add any other protected routes here
    end
  end
end
