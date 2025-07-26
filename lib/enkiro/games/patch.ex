defmodule Enkiro.Games.Patch do
  @moduledoc """
  Represents a game patch in the Enkiro system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "game_patches" do
    field :version_string, :string
    field :release_date, :date
    field :notes_url, :string
    field :game_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(patch, attrs) do
    patch
    |> cast(attrs, [:version_string, :release_date, :notes_url])
    |> validate_required([:version_string, :release_date, :notes_url])
  end
end
