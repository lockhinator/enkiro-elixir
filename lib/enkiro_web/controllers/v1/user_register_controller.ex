defmodule EnkiroWeb.V1.UserRegisterController do
  use EnkiroWeb, :controller

  alias Enkiro.Accounts

  def create(conn, %{"user" => user_params}) do
    with {:ok, user} <- Accounts.register_user(user_params) do
      conn
      |> put_status(:created)
      |> render("show.json", %{user: user})
    end
  end
end
