defmodule Enkiro.Content.Comment do
  @moduledoc """
  Represents a comment on a post in the Enkiro content system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "comments" do
    field :path, :string
    field :body, :string
    field :details, :map
    field :post_id, :binary_id
    field :author_id, :binary_id
    field :parent_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:path, :body, :details])
    |> validate_required([:path, :body])
  end
end
