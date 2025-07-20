defmodule EnkiroWeb.V1.UserProfileJSON do
  def render("show.json", %{user: user}) do
    %{
      data: %{
        id: user.id,
        email: user.email,
        gamer_tag: user.gamer_tag,
        subscription_tier: user.subscription_tier
      }
    }
  end
end
