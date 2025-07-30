defmodule EnkiroWeb.V1.FollowJSON do
  import EnkiroWeb.ViewHelpers

  alias EnkiroWeb.V1.{GamesJSON, UserProfileJSON}

  def render("index.json", %{follows: {follows, _meta}}) do
    %{
      "data" => Enum.map(follows, &render("follow.json", %{follow: &1}))
    }
  end

  def render("follow.json", %{follow: follow}) do
    %{
      "id" => follow.id,
      "user_id" => follow.user_id,
      "user" => render_one_preloaded(UserProfileJSON, "show.json", %{user: follow.user}),
      "game_id" => follow.game_id,
      "game" => render_one_preloaded(GamesJSON, "show.json", %{game: follow.game}),
      "inserted_at" => follow.inserted_at,
      "updated_at" => follow.updated_at
    }
  end
end
