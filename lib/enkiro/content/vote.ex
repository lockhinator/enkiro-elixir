defmodule Enkiro.Content.Vote do
  @moduledoc """
  Represents a vote on a votable entity in the Enkiro system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Enkiro.Types
  alias Enkiro.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "votes" do
    field :votable_id, :binary
    field :votable_type, Ecto.Enum, values: Types.votable_types()
    field :vote_type, Ecto.Enum, values: Types.vote_type_values()
    belongs_to :user, User, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:votable_id, :votable_type, :vote_type])
    |> validate_required([:votable_id, :votable_type, :vote_type])
  end
end
