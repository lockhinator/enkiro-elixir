defmodule Enkiro.Games do
  @moduledoc """
  The Games context manages game-related data and operations.
  """
  alias Enkiro.Repo
  alias Enkiro.Accounts.User
  alias Enkiro.Games.{Game, Studio, Publisher}

  def list_games(params \\ %{}),
    do: Flop.validate_and_run!(Game, params, for: Game, replace_invalid_params: true)

  def get_game(id, preloads \\ []),
    do: Repo.get(Game, id, preloads: preloads)

  def get_game_by(attrs, preloads \\ []),
    do: Repo.get_by(Game, attrs, preloads: preloads)

  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  def user_create_game(%User{} = user, attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> PaperTrail.insert(originator: user)
  end

  def user_update_game(%User{} = user, %Game{} = game, attrs \\ %{}) do
    game
    |> Game.changeset(attrs)
    |> PaperTrail.update(originator: user)
  end

  def user_delete_game(%User{} = user, %Game{} = game) do
    PaperTrail.delete(game, originator: user)
  end

  def list_publishers(preloads \\ []),
    do: Repo.all(Publisher, preloads: preloads)

  def create_publisher(attrs \\ %{}) do
    %Publisher{}
    |> Publisher.changeset(attrs)
    |> Repo.insert()
  end

  def update_publisher(%Publisher{} = publisher, attrs \\ %{}) do
    publisher
    |> Publisher.changeset(attrs)
    |> Repo.update()
  end

  def get_publisher(id, preloads \\ []),
    do: Repo.get(Publisher, id, preloads: preloads)

  def delete_publisher(%Publisher{} = publisher),
    do: Repo.delete(publisher)

  def create_studio(attrs \\ %{}) do
    %Studio{}
    |> Studio.changeset(attrs)
    |> Repo.insert()
  end

  def list_studios(preloads \\ []),
    do: Repo.all(Studio, preloads: preloads)
end
