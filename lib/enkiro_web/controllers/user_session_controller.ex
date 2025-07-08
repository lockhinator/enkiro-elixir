defmodule EnkiroWeb.UserSessionController do
  use EnkiroWeb, :controller

  alias Enkiro.Accounts
  alias Enkiro.Guardian, as: EnkiroGuardian

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.login_user(email, password) do
      {:ok, user} ->
        {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user)

        conn
        |> put_status(:ok)
        |> render("show.json", %{user: user, token: token})

      {:error, _reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: %{status: 401, message: "Invalid email or password"}})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: %{status: 400, message: "Invalid request"}})
  end

  def delete(conn, _params) do
    ["Bearer" <> token] = get_req_header(conn, "authorization")

    case EnkiroGuardian.revoke(String.trim(token)) do
      {:ok, _} ->
        conn
        |> put_status(200)
        |> json(%{status: 200, message: "Logout successful"})

      {:error, _reason} ->
        conn
        |> put_status(500)
        |> json(%{error: %{status: 500, message: "Logout failed"}})
    end
  end
end
