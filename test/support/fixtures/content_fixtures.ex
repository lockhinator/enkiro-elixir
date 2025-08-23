defmodule Enkiro.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Enkiro.Content` context.
  """

  alias Enkiro.Accounts.User
  alias Enkiro.Content
  alias Enkiro.GamesFixtures

  @doc """
  Generate a post.
  """
  def post_fixture(%User{} = author, attrs \\ %{}) do
    game = GamesFixtures.game_fixture()
    patch = GamesFixtures.patch_fixture(game)

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

    status = Map.get(attrs, :status)

    # some hackery to set a post to deleted status
    # since posts can't be created with deleted status
    if not is_nil(status) and status == :deleted do
      attrs = Map.delete(attrs, :status)
      {:ok, post} = Content.create_post(author, attrs)
      {:ok, post} = Content.delete_post(post, author)
      post
    else
      {:ok, post} = Content.create_post(author, attrs)
      post
    end
  end
end
