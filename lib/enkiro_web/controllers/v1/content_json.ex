defmodule EnkiroWeb.V1.ContentJSON do
  import EnkiroWeb.ViewHelpers

  alias EnkiroWeb.V1.GamesJSON

  def render("index.json", %{posts: {posts, meta}}) do
    %{
      data:
        Enum.map(posts, fn post ->
          render("post.json", %{post: post})
        end),
      meta: render_flop_meta(meta)
    }
  end

  def render("post.json", %{post: post}) do
    %{
      id: post.id,
      title: post.title,
      post_type: post.post_type,
      status: post.status,
      author_id: post.author_id,
      author: render_one_preloaded(__MODULE__, "user.json", %{user: post.author}),
      game_patch_id: post.game_patch_id,
      game_patch:
        render_one_preloaded(__MODULE__, "game_patch.json", %{game_patch: post.game_patch}),
      game_id: post.game_id,
      game: render_one_preloaded(GamesJSON, "show.json", %{game: post.game}),
      details: post.details
    }
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      gamer_tag: user.gamer_tag,
      reputation_tier: user.reputation_tier
    }
  end

  def render("game_patch.json", %{game_patch: game_patch}) do
    %{
      version_string: game_patch.version_string,
      release_date: game_patch.release_date,
      notes_url: game_patch.notes_url
    }
  end
end
