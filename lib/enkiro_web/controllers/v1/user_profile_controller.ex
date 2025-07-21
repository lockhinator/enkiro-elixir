defmodule EnkiroWeb.V1.UserProfileController do
  use EnkiroWeb, :controller

  alias Enkiro.Accounts.User
  alias Enkiro.Accounts

  def show_me(conn, _params) do
    # Guardian has already loaded the user into the conn for us
    current_user = Guardian.Plug.current_resource(conn)
    render(conn, "show.json", %{user: current_user})
  end

  def update_me(conn, %{"user" => user_params}) do
    with %User{} = current_user <- Guardian.Plug.current_resource(conn),
         {:ok, user} <- Accounts.update_user(current_user, user_params) do
      render(conn, "show.json", %{user: user})
    end
  end

  def update_password_me(conn, %{
        "user" => %{"current_password" => current_password, "new_password" => new_password}
      }) do
    with %User{} = current_user <- Guardian.Plug.current_resource(conn),
         {:ok, user} <-
           Accounts.update_user_password(current_user, current_password, %{password: new_password}) do
      render(conn, "show.json", %{user: user})
    end
  end
end
