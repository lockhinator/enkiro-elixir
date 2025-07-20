defmodule EnkiroWeb.V1.UserProfileController do
  use EnkiroWeb, :controller

  def show_me(conn, _params) do
    # Guardian has already loaded the user into the conn for us
    current_user = Guardian.Plug.current_resource(conn)
    render(conn, "show.json", %{user: current_user})
  end
end
