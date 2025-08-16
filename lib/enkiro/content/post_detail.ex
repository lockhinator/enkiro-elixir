defmodule Enkiro.Content.PostDetail do
  @moduledoc """
  A container for all embedded schemas related to the Post `details` field.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @derive Jason.Encoder

  @primary_key false
  embedded_schema do
    field :post_type, Ecto.Enum, values: Enkiro.Types.post_type_values()
    field :ratings, :map, default: %{}
    field :playstyle, {:array, :string}, default: []
    field :hours_played, :string
    field :replication_steps, :string
    field :media_url, :string
    field :publication_type, Ecto.Enum, values: [:article, :video]
    field :body_markdown, :string
    field :video_url, :string
  end

  def changeset(detail, attrs) do
    detail
    |> cast(attrs, [
      :post_type,
      :ratings,
      :playstyle,
      :hours_played,
      :replication_steps,
      :media_url,
      :publication_type,
      :body_markdown,
      :video_url
    ])
    |> validate_required([:post_type])
    |> validate_details_changeset()
  end

  defp validate_details_changeset(changeset) do
    post_type = get_field(changeset, :post_type)

    cond do
      post_type == :player_report ->
        validate_required(changeset, [:ratings, :hours_played])

      post_type == :bug_report ->
        validate_required(changeset, [:replication_steps])

      post_type == :publication ->
        changeset
        |> validate_required([:publication_type])
        |> validate_publication_fields()

      true ->
        changeset
    end
  end

  defp validate_publication_fields(changeset) do
    type = get_field(changeset, :publication_type)

    cond do
      type == :article ->
        validate_required(changeset, [:body_markdown])

      type == :video ->
        validate_required(changeset, [:video_url])

      true ->
        changeset
    end
  end
end
