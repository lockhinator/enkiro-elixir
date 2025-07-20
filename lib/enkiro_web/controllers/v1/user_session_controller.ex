defmodule EnkiroWeb.V1.UserSessionController do
  use EnkiroWeb, :controller

  alias Enkiro.Accounts.User
  alias Enkiro.Accounts
  alias Enkiro.Guardian, as: EnkiroGuardian

  @refresh_cookie_name "enkiro_refresh"

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.login_user(email, password) do
      {:ok, user} ->
        {:ok, access_token, _claims} =
          EnkiroGuardian.encode_and_sign(user, %{}, token_type: :access, ttl: {1, :hour})

        {:ok, refresh_token, _claims} =
          EnkiroGuardian.encode_and_sign(user, %{}, token_type: :refresh, ttl: {7, :day})

        conn
        |> put_resp_cookie(
          @refresh_cookie_name,
          refresh_token,
          # Cookie security options
          # Not accessible via JavaScript
          http_only: true,
          # Only send over HTTPS in production
          secure: Mix.env() == :prod,
          # Available for the whole site
          path: "/",
          # Provides good CSRF protection
          same_site: "Lax"
        )
        |> put_status(:ok)
        |> render("show.json", %{user: user, access_token: access_token})

      {:error, _reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{errors: %{status: 401, message: "Invalid email or password"}})
    end
  end

  def refresh(%Plug.Conn{req_cookies: %{"enkiro_refresh" => refresh_token}} = conn, _params) do
    with {:ok, %{"sub" => user_id}} <- EnkiroGuardian.decode_and_verify(refresh_token),
         {:ok, %User{} = _user} <- {:ok, Accounts.get_user(user_id)},
         {:ok, _old_stuff, {new_token, _new_claims}} <-
           EnkiroGuardian.exchange(refresh_token, "refresh", "access", ttl: {1, :hour}) do
      conn
      |> put_status(:ok)
      |> put_resp_header("authorization", "Bearer #{new_token}")
      |> resp(200, "")
    else
      # This case handles when the refresh token is invalid or missing
      {:error, _reason} ->
        put_status(conn, :unauthorized)
    end
  end

  def refresh(_conn, _params), do: {:error, :unauthorized}

  def delete(conn, _params) do
    # Use pattern matching to extract the token and revoke it directly
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, _} <- EnkiroGuardian.revoke(String.trim(token)) do
      conn
      # Ensure you have @refresh_cookie_name defined
      |> delete_resp_cookie(@refresh_cookie_name)
      |> put_status(:ok)
      |> json(%{message: "Logout successful"})
    else
      # This will catch cases where the header is missing or revoke fails
      _ ->
        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: "Unauthorized"}})
    end
  end
end
