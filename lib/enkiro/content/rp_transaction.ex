defmodule Enkiro.Content.RpTransaction do
  @moduledoc """
  Represents a reputation point transaction in the Enkiro system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Enkiro.Accounts.User
  alias Enkiro.Games.Game
  alias Enkiro.Types

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rp_transactions" do
    field :amount, :integer
    field :event_type, Ecto.Enum, values: Types.rp_event_type_values()
    field :source_id, :binary
    field :source_type, Ecto.Enum, values: Types.rp_source_type_values()

    belongs_to :user, User
    belongs_to :game, Game

    timestamps(updated_at: false, type: :utc_datetime)
  end

  @doc false
  def changeset(rp_transaction, attrs) do
    rp_transaction
    |> cast(attrs, [:amount, :event_type, :source_id, :source_type, :user_id, :game_id])
    |> validate_required([:amount, :event_type, :source_id, :source_type])
  end
end
