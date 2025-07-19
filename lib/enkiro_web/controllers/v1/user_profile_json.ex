defmodule EnkiroWeb.V1.UserProfileJSON do
  def render("show.json", %{user: user}) do
    %{
      data: %{
        id: user.id,
        email: user.email
      }
    }
  end
end
