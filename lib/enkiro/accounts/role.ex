defmodule Enkiro.Accounts.Role do
  @moduledoc """
  Represents a role in the Enkiro system.
  This module defines the schema for the `roles` table, which contains information about user roles
  and their associated permissions.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "roles" do
    field :name, :string
    field :api_name, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :api_name])
    |> validate_required([:name, :api_name])
    |> unique_constraint(:name)
    |> unique_constraint(:api_name)
  end
end
