defmodule EnkiroWeb.V1.GamesJSON do
  alias Enkiro.Games.Game
  alias Enkiro.Games.Studio

  def render("index.json", %{games: {games, %Flop.Meta{}}}) do
    %{data: Enum.map(games, &render("game.json", %{game: &1}))}
  end

  def render("show.json", %{game: %{model: %Game{} = game}}) do
    %{data: render("game.json", %{game: game})}
  end

  def render("show.json", %{game: %Game{} = game}) do
    %{data: render("game.json", %{game: game})}
  end

  def render("game.json", %{game: game}) do
    %{
      id: game.id,
      status: game.status,
      title: game.title,
      slug: game.slug,
      genre: game.genre,
      release_date: game.release_date,
      ai_overview: game.ai_overview,
      publisher_overview: game.publisher_overview,
      logo_path: game.logo_path,
      cover_art_path: game.cover_art_path,
      store_url: game.store_url,
      steam_appid: game.steam_appid,
      studio_id: game.studio_id,
      studio: render("studio.json", %{studio: game.studio})
    }
  end

  def render("studio.json", %{studio: %Studio{} = studio}) do
    %{
      name: studio.name
    }
  end

  def render("studio.json", %{studio: _}), do: nil
end
