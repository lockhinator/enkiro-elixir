defmodule Enkiro.Games.Studio do
  @moduledoc """
  Represents a game studio in the Enkiro system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "game_studios" do
    field :name, :string
    field :publisher_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(studio, attrs) do
    studio
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
