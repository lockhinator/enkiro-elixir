defmodule Enkiro.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Enkiro.Content` context.
  """

  alias Enkiro.Accounts.User
  alias Enkiro.Content

  @doc """
  Generate a post.
  """
  def post_fixture(%User{} = author, attrs \\ %{}) do
    game = Enkiro.GamesFixtures.game_fixture()
    patch = Enkiro.GamesFixtures.patch_fixture(game)

    default_attrs = %{
      game_id: game.id,
      game_patch_id: patch.id,
      post_type: :player_report,
      title: "A great patch with some minor issues",
      details: %{
        ratings: %{"gameplay_loop" => 4, "performance" => 5},
        hours_played: "500+"
      }
    }

    attrs = Enum.into(attrs, default_attrs)

    {:ok, post} = Content.create_post(author, attrs)

    post
  end
end
