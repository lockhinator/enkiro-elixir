defmodule EnkiroWeb.Pipelines.ApiProtected do
  @moduledoc """
  This pipeline is used for API endpoints that require authentication.
  """
  use Guardian.Plug.Pipeline,
    otp_app: :enkiro,
    module: Enkiro.Guardian,
    error_handler: Enkiro.AuthErrorHandler

  # Simplified VerifyHeader configuration
  plug EnkiroWeb.Plugs.AuthHeader

  # Basic authentication verification
  plug Guardian.Plug.EnsureAuthenticated

  # Simple resource loading
  plug Guardian.Plug.LoadResource
end
