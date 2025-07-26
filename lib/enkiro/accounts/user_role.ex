defmodule Enkiro.Accounts.UserRole do
  @moduledoc """
  Represents the association between users and roles in the Enkiro system.
  This module defines the schema for the `users_roles` table, which links users to their roles.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Enkiro.Accounts.{User, Role}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users_roles" do
    belongs_to :user, User, type: :binary_id
    belongs_to :role, Role, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  def changeset(user_role, attrs) do
    user_role
    |> cast(attrs, [:user_id, :role_id])
    |> validate_required([:user_id, :role_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:role_id)
  end
end
