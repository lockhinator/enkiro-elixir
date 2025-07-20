defmodule EnkiroWeb.V1.UserProfileController do
  use EnkiroWeb, :controller

  alias Enkiro.Accounts.User

  def show_me(conn, _params) do
    # Guardian has already loaded the user into the conn for us
    current_user = Guardian.Plug.current_resource(conn)
    render(conn, "show.json", %{user: current_user})
  end

  def update_me(conn, %{"user" => user_params}) do
    with %User{} = current_user <- Guardian.Plug.current_resource(conn),
         {:ok, user} <- Enkiro.Accounts.update_user(current_user, user_params) do
      render(conn, "show.json", %{user: user})
    end
  end
end
