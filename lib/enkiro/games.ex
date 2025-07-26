defmodule Enkiro.Games do
  @moduledoc """
  The Games context manages game-related data and operations.
  """
  alias Enkiro.Repo
  alias Enkiro.Accounts.User
  alias Enkiro.Games.{Game, Studio, Publisher}

  @doc """
  Lists all games with optional filtering and pagination.
  Accepts a map of parameters for filtering, sorting, and pagination.
  """
  def list_games(params \\ %{}),
    do: Flop.validate_and_run!(Game, params, for: Game, replace_invalid_params: true)

  @doc """
  Gets a game by ID, with optional preloads.
  Returns `nil` if the game does not exist.
  """
  def get_game(id, preloads \\ []),
    do: Repo.get(Game, id, preloads: preloads)

  @doc """
  Gets a game by attributes, with optional preloads.
  Returns `nil` if no game matches the attributes.
  """
  def get_game_by(attrs, preloads \\ []),
    do: Repo.get_by(Game, attrs, preloads: preloads)

  @doc """
  Creates a new game with the given attributes.
  Returns `{:ok, game}` on success or `{:error, changeset}` on failure.
  """
  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing game with the given attributes.
  Returns `{:ok, %{version: version_data, model: game}}` on success or `{:error, changeset}` on failure.
  """
  def user_create_game(%User{} = user, attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> PaperTrail.insert(originator: user)
  end

  @doc """
  Updates an existing game with the given attributes.
  Returns `{:ok, %{version: version_data, model: game}}` on success or `{:error, changeset}` on failure.
  """
  def user_update_game(%User{} = user, %Game{} = game, attrs \\ %{}) do
    game
    |> Game.changeset(attrs)
    |> PaperTrail.update(originator: user)
  end

  @doc """
  Deletes a game.
  Returns `{:ok, %{version: version_data, model: game}}` on success or `{:error, changeset}` on failure.
  """
  def user_delete_game(%User{} = user, %Game{} = game) do
    PaperTrail.delete(game, originator: user)
  end

  @doc """
  Lists all publishers with optional preloads.
  """
  def list_publishers(preloads \\ []),
    do: Repo.all(Publisher, preloads: preloads)

  @doc """
  Creates a new publisher with the given attributes.
  Returns `{:ok, publisher}` on success or `{:error, changeset}` on failure.
  """
  def create_publisher(attrs \\ %{}) do
    %Publisher{}
    |> Publisher.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing publisher with the given attributes.
  Returns `{:ok, publisher}` on success or `{:error, changeset}` on failure.
  """
  def update_publisher(%Publisher{} = publisher, attrs \\ %{}) do
    publisher
    |> Publisher.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets a publisher by ID, with optional preloads.
  Returns `nil` if the publisher does not exist.
  """
  def get_publisher(id, preloads \\ []),
    do: Repo.get(Publisher, id, preloads: preloads)

  @doc """
  Deletes a publisher.
  Returns `{:ok, publisher}` on success or `{:error, changeset}` on failure.
  """
  def delete_publisher(%Publisher{} = publisher),
    do: Repo.delete(publisher)

  @doc """
  Creates a new studio with the given attributes.
  Returns `{:ok, studio}` on success or `{:error, changeset}` on failure.
  """
  def create_studio(attrs \\ %{}) do
    %Studio{}
    |> Studio.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists all studios with optional preloads.
  """
  def list_studios(preloads \\ []),
    do: Repo.all(Studio, preloads: preloads)
end
