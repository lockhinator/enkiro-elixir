defmodule Enkiro.Games do
  @moduledoc """
  The Games context manages game-related data and operations.
  """
  import Ecto.Changeset, only: [add_error: 3]

  alias Enkiro.Repo
  alias Enkiro.Accounts.User
  alias Enkiro.Games.{Game, Studio, Publisher}
  alias Enkiro.ImageUtils

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
    do: Repo.get(Game, id) |> Repo.preload(preloads)

  @doc """
  Gets a game by attributes, with optional preloads.
  Returns `nil` if no game matches the attributes.
  """
  def get_game_by(attrs, preloads \\ []),
    do: Repo.get_by(Game, attrs) |> Repo.preload(preloads)

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
    create_update_user_game(user, %Game{}, attrs, fn changeset, user ->
      PaperTrail.insert(changeset, originator: user)
    end)
  end

  @doc """
  Updates an existing game with the given attributes.
  Returns `{:ok, %{version: version_data, model: game}}` on success or `{:error, changeset}` on failure.
  """
  def user_update_game(%User{} = user, %Game{} = game, attrs \\ %{}) do
    create_update_user_game(user, game, attrs, fn changeset, user ->
      PaperTrail.update(changeset, originator: user)
    end)
  end

  defp create_update_user_game(%User{} = user, %Game{} = game, attrs, db_action) do
    game_attrs =
      attrs
      |> Jason.encode!()
      |> Jason.decode!()

    Ecto.Multi.new()
    |> fetch_original_game(game)
    |> handle_studio(game_attrs, user, game)
    |> handle_game_update(db_action, game_attrs, user, game)
    |> handle_image_cleanup(game_attrs)
    |> Repo.transaction()
    |> handle_transaction_result()
  end

  defp fetch_original_game(multi, game) do
    Ecto.Multi.run(multi, :original_game, fn repo, _ ->
      if game.id do
        {:ok, repo.get(Game, game.id) || game}
      else
        {:ok, game}
      end
    end)
  end

  defp handle_studio(multi, game_attrs, user, game) do
    Ecto.Multi.run(multi, :studio, fn repo, _ ->
      find_or_create_studio(repo, game_attrs, user, game)
    end)
  end

  def find_or_create_studio(repo, attrs, user, game \\ %Game{}) do
    studio_id = Map.get(attrs, "studio_id", game.studio_id)
    studio_attrs = Map.get(attrs, "studio")

    cond do
      is_binary(studio_id) ->
        case repo.get(Studio, studio_id) do
          %Studio{} = studio ->
            {:ok, studio}

          _ ->
            {:error, :not_found}
        end

      is_map(studio_attrs) and Map.has_key?(studio_attrs, "name") ->
        get_or_create_studio(repo, user, studio_attrs)

      true ->
        game
        |> Game.changeset(attrs)
        |> add_error(
          :studio,
          "must be provided as a `studio_id` or a nested `studio` map with a `name` field"
        )
        |> then(&{:error, &1})
    end
  end

  defp get_or_create_studio(repo, user, studio_attrs) do
    case repo.get_by(Studio, name: Map.get(studio_attrs, "name")) do
      %Studio{} = studio ->
        {:ok, studio}

      _ ->
        %Studio{}
        |> Studio.changeset(studio_attrs)
        |> PaperTrail.insert(originator: user)
        |> case do
          {:ok, %{version: _version, model: studio}} ->
            {:ok, studio}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  defp handle_game_update(multi, db_action, game_attrs, user, game) do
    multi
    |> Ecto.Multi.run(:logo_image, fn _repo, _ ->
      maybe_save_image("logo_data", game_attrs, game.logo_path)
    end)
    |> Ecto.Multi.run(:cover_art_image, fn _repo, _ ->
      maybe_save_image("cover_art_data", game_attrs, game.cover_art_path)
    end)
    |> Ecto.Multi.run(:game, fn _repo,
                                %{
                                  studio: %Studio{id: studio_id},
                                  logo_image: %{path: logo_path},
                                  cover_art_image: %{path: cover_art_path}
                                } ->
      game_attrs =
        game_attrs
        |> Map.put("logo_path", logo_path)
        |> Map.put("cover_art_path", cover_art_path)
        |> Map.put("studio_id", studio_id)

      game
      |> Game.changeset(game_attrs)
      |> db_action.(user)
    end)
  end

  defp maybe_save_image(field, game_attrs, current_image_path) do
    if Map.has_key?(game_attrs, field) do
      with {:ok, image_type, image_temp_path} <-
             ImageUtils.create_temp_from_base64(Map.get(game_attrs, field)),
           {:ok, image_path} <- ImageUtils.save_permanent_image(image_type, image_temp_path) do
        {:ok, %{path: image_path}}
      end
    else
      {:ok, %{path: current_image_path}}
    end
  end

  defp handle_image_cleanup(multi, game_attrs) do
    Ecto.Multi.run(multi, :clean_prior_images, fn _repo,
                                                  %{
                                                    game: %{model: upsert_game},
                                                    original_game: original_game
                                                  } ->
      case clean_game_images(original_game, upsert_game) do
        {:ok, result} ->
          {:ok, result}

        {:error, message} ->
          upsert_game
          |> Game.changeset(game_attrs)
          |> add_error(:logo_path, message)
          |> then(&{:error, &1})
      end
    end)
  end

  defp handle_transaction_result(result) do
    case result do
      {:ok, %{game: %{version: version, model: %Game{} = game}}} ->
        {:ok, %{version: version, model: Repo.preload(game, :studio)}}

      {:ok, %{game: %{model: %Game{} = game}}} ->
        {:ok, %{version: nil, model: Repo.preload(game, :studio)}}

      {:error, :studio, reason, changes_so_far} ->
        delete_created_images(changes_so_far)
        {:error, reason}

      {:error, :game, changeset, changes_so_far} ->
        delete_created_images(changes_so_far)
        {:error, changeset}
    end
  end

  defp delete_created_images(%{
         logo_image: %{path: logo_path},
         cover_art_image: %{path: cover_art_path}
       })
       when not is_nil(logo_path) or not is_nil(cover_art_path) do
    with :ok <- ImageUtils.delete_permanent_image(logo_path),
         :ok <- ImageUtils.delete_permanent_image(cover_art_path) do
      {:ok, %{logo_deleted: true, cover_art_deleted: true}}
    end
  end

  defp delete_created_images(_changes_so_far) do
    {:ok, %{logo_deleted: false, cover_art_deleted: false}}
  end

  defp clean_game_images(original_game, upsert_game) do
    with :ok <- maybe_delete_cover_art(original_game, upsert_game),
         :ok <- maybe_delete_logo(original_game, upsert_game) do
      {:ok, %{cover_art_deleted: true, logo_deleted: true}}
    else
      _error -> {:error, "Failed to delete logo or cover art image"}
    end
  end

  defp maybe_delete_cover_art(original_game, upsert_game) do
    if should_delete_image?(original_game.cover_art_path, upsert_game.cover_art_path) do
      ImageUtils.delete_permanent_image(original_game.cover_art_path)
    else
      :ok
    end
  end

  defp maybe_delete_logo(original_game, upsert_game) do
    if should_delete_image?(original_game.logo_path, upsert_game.logo_path) do
      ImageUtils.delete_permanent_image(original_game.logo_path)
    else
      :ok
    end
  end

  defp should_delete_image?(original_path, new_path) do
    not is_nil(original_path) and
      original_path != new_path and
      ImageUtils.permanent_image_exists?(new_path)
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
