defmodule EnkiroWeb.V1.UserSessionJSON do
  def render("show.json", %{user: user, token: token}) do
    %{
      data: %{
        id: user.id,
        email: user.email,
        token: token
      }
    }
  end
end
