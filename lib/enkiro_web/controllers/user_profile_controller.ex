defmodule EnkiroWeb.UserProfileController do
  use EnkiroWeb, :controller

  def show(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    if user do
      conn
      |> put_status(:ok)
      |> render("show.json", %{user: user, token: Guardian.Plug.current_token(conn)})
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: %{status: 401, message: "Unauthorized"}})
    end
  end
end
