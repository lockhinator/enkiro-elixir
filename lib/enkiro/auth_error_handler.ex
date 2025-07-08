defmodule Enkiro.AuthErrorHandler do
  @moduledoc """
  Error handler for Guardian authentication errors.
  This module handles authentication errors by returning a JSON response with a 401 status code.
  It implements the `Guardian.Plug.ErrorHandler` behaviour.
  """
  import Plug.Conn

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {_type, _reason}, _opts) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{error: %{status: 401, message: "Unauthorized"}}))
  end
end
