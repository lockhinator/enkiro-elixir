defmodule EnkiroWeb.V1.UserSessionJSON do
  def render("show.json", %{user: user, access_token: access_token}) do
    %{
      data: %{
        id: user.id,
        email: user.email,
        access_token: access_token
      }
    }
  end

  def render("refresh.json", %{access_token: access_token}) do
    %{
      access_token: access_token
    }
  end
end
