defmodule EnkiroWeb.V1.UserRegisterJSON do
  def render("show.json", %{user: user}) do
    %{
      data: %{
        email: user.email
      }
    }
  end
end
