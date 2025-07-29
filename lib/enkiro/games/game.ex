defmodule Enkiro.Games.Game do
  @moduledoc """
  Represents a game in the Enkiro system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Enkiro.Games.Studio

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

    field :cover_art_data, :string, virtual: true
    field :logo_data, :string, virtual: true

    belongs_to :studio, Studio, foreign_key: :studio_id

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
      :steam_appid,
      :studio_id,

      # the virtual fields used to upload images
      # the data is base64 encoded so we can decode it
      # and store the image locally
      :cover_art_data,
      :logo_data
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
      :studio_id
    ])
    |> unique_constraint(:slug)
    |> unique_constraint(:title)
    |> replace_date_error(:release_date)
    |> foreign_key_constraint(:studio_id)
  end

  def images_changeset(game, attrs) do
    game
    |> cast(attrs, [:cover_art_data, :logo_data])
    |> validate_required([:cover_art_data, :logo_data])
    |> validate_length(:cover_art_data, min: 1)
    |> validate_length(:logo_data, min: 1)
  end

  def game_statuses, do: @game_statuses

  defp set_slug(changeset) do
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

  # replaces the default Ecto date error with a easier to understand custom format error
  defp replace_date_error(changeset, field) do
    case get_in(changeset.errors, [field]) do
      {_, [type: :date, validation: :cast]} ->
        changeset
        |> Map.update!(:errors, &List.keydelete(&1, field, 0))
        |> add_error(field, "must be in YYYY-MM-DD format", validation: :format)

      _ ->
        changeset
    end
  end
end
