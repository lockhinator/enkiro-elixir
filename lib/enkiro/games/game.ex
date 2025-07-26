defmodule Enkiro.Games.Game do
  @moduledoc """
  Represents a game in the Enkiro system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:title, :genre, :status, :studio_id], sortable: [:title, :release_date]
  }

  @game_statuses [
    # The game is public knowledge, but not yet playable by the public. This is a good catch-all for the early stages.
    :announced,
    # Playable by a limited, invited group.
    :closed_beta,
    # Publicly playable for a limited time before launch.
    :open_beta,
    # Available for purchase and play, but considered incomplete. A crucial stage for modern games.
    :early_access,
    # The game is fully launched and receiving active content updates. This should be the default status for most live games.
    :released,
    # The game is stable and playable but is no longer receiving major content updates (e.g., only critical bug fixes or seasonal reruns).
    :legacy_support,
    # Development was officially stopped before the game was released.
    :cancelled,
    # The developer has officially announced that the game's servers will be shut down in the near future.
    :sunsetting,
    # The game is permanently offline and no longer playable
    :sunsetted
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "games" do
    field :status, Ecto.Enum, values: @game_statuses
    field :title, :string
    field :slug, :string
    field :genre, :string
    field :release_date, :date
    field :ai_overview, :string
    field :publisher_overview, :string
    field :logo_path, :string
    field :cover_art_path, :string
    field :store_url, :string
    field :steam_appid, :integer
    field :studio_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [
      :title,
      :genre,
      :release_date,
      :status,
      :ai_overview,
      :publisher_overview,
      :logo_path,
      :cover_art_path,
      :store_url,
      :steam_appid
    ])
    |> set_slug()
    |> validate_required([
      :title,
      :slug,
      :genre,
      :release_date,
      :status,
      :ai_overview,
      :publisher_overview,
      :logo_path,
      :cover_art_path,
      :store_url,
      :steam_appid
    ])
    |> unique_constraint(:slug)
  end

  def set_slug(changeset) do
    case get_field(changeset, :title) do
      nil ->
        changeset

      title when is_binary(title) and title != "" ->
        slug = Slug.slugify(title, separator: "-")
        put_change(changeset, :slug, slug)

      _ ->
        changeset
    end
  end

  def game_statuses, do: @game_statuses
end
