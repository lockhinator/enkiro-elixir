defmodule Enkiro.Accounts.UserFollow do
  @moduledoc """
  Represents a user's follow of a game in the Enkiro application.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Enkiro.Games.Game
  alias Enkiro.Accounts.User

  @derive {
    Flop.Schema,
    filterable: [:user_id, :game_id],
    sortable: [:inserted_at],
    default_order: %{
      order_by: [:inserted_at],
      order_directions: [:desc]
    }
  }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_follows" do
    belongs_to :user, User
    belongs_to :game, Game

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_follow, attrs) do
    user_follow
    |> cast(attrs, [
      :user_id,
      :game_id
    ])
    |> validate_required([
      :user_id,
      :game_id
    ])
    |> unique_constraint(:user_id,
      name: :user_follows_user_id_game_id_index,
      message: "You are already following this game.",
      error_key: :game_id
    )
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:game_id)
  end
end
