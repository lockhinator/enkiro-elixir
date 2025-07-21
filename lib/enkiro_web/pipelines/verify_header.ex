defmodule EnkiroWeb.Plugs.AuthHeader do
  @moduledoc """
  This plug extracts the Authorization header from the request and verifies the token.
  It sets the current user in the connection if the token is valid.
  If the token is invalid or missing, it returns a 401 Unauthorized response.
  """
  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case verify_token(token) do
          {:ok, claims, resource} ->
            conn
            |> Guardian.Plug.put_current_token(token)
            |> Guardian.Plug.put_current_claims(claims)
            |> Guardian.Plug.put_current_resource(resource)
            |> assign(:current_user, resource)

          _ ->
            unauthorized(conn)
        end

      _ ->
        unauthorized(conn)
    end
  end

  defp verify_token(token) do
    with {:ok, claims} <- Enkiro.Guardian.decode_and_verify(token),
         {:ok, resource} <- Enkiro.Guardian.resource_from_claims(claims) do
      {:ok, claims, resource}
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_status(:unauthorized)
    |> Phoenix.Controller.put_view(json: EnkiroWeb.ErrorJSON)
    |> Phoenix.Controller.json(%{"error" => %{"message" => "Unauthorized", "status" => 401}})
    |> halt()
  end
end
