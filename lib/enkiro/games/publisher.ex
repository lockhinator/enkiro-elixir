defmodule Enkiro.Games.Publisher do
  @moduledoc """
  Represents a game publisher in the Enkiro system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "game_publishers" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(publisher, attrs) do
    publisher
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
