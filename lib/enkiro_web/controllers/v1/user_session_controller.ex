defmodule EnkiroWeb.V1.UserSessionController do
  use EnkiroWeb, :controller

  alias Enkiro.Accounts
  alias Enkiro.Guardian, as: EnkiroGuardian

  @refresh_cookie_name "enkiro_refresh"

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.login_user(email, password) do
      {:ok, user} ->
        {:ok, access_token, _claims} =
          EnkiroGuardian.encode_and_sign(user, %{}, token_type: :access, ttl: {1, :hour})

        {:ok, refresh_token, _claims} =
          EnkiroGuardian.encode_and_sign(user, %{}, token_type: :refresh, ttl: {7, :minute})

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
          path: "/api/v1/users/refresh",
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

  def refresh(conn, _params) do
    # Use a case statement to safely get the header
    case get_req_header(conn, "authorization") do
      [new_access_token] ->
        # This is the success case, the pipeline added the header
        conn
        |> put_status(:ok)
        |> render("refresh.json", %{access_token: new_access_token})

      [] ->
        # This is the failure case, the pipeline did not add the header
        # This should theoretically not be hit if the pipeline's error_handler works,
        # but it makes the controller robust against crashes.
        conn
        |> put_status(:unauthorized)
        |> json(%{error: %{status: 401, message: "Unauthorized"}})
    end
  end

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
