defmodule Enkiro.GamesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Enkiro.Games` context.
  """

  @example_genres [
    "Action",
    "Adventure",
    "Role-playing",
    "Simulation",
    "Strategy",
    "Sports",
    "Puzzle",
    "Horror",
    "Racing",
    "Platformer"
  ]

  @valid_statuses Enkiro.Games.Game.game_statuses()

  def valid_status, do: Enum.random(@valid_statuses)
  def valid_genre, do: Enum.random(@example_genres)
  def valid_game_title, do: Faker.Lorem.words(2) |> Enum.join(" ")
  def valid_ai_overview, do: Faker.Lorem.paragraph(3..5)
  def valid_publisher_overview, do: Faker.Lorem.paragraph(3..5)
  def valid_logo_path, do: "logo_#{System.unique_integer()}.png"
  def valid_cover_art_path, do: "cover_art_#{System.unique_integer()}.png"
  def valid_store_url, do: "https://example.com/store/#{Faker.Internet.slug()}"

  def valid_game_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      status: valid_status(),
      title: valid_game_title(),
      genre: valid_genre(),
      release_date: Date.utc_today(),
      ai_overview: valid_ai_overview(),
      publisher_overview: valid_publisher_overview(),
      logo_path: valid_logo_path(),
      cover_art_path: valid_cover_art_path(),
      store_url: valid_store_url(),
      steam_appid: Enum.random(1000..9999)
    })
  end

  def game_fixture(attrs \\ %{}) do
    {:ok, game} =
      attrs
      |> valid_game_attributes()
      |> Enkiro.Games.create_game()

    game
  end
end
