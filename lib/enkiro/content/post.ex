defmodule Enkiro.Content.Post do
  @moduledoc """
  Represents a post in the Enkiro content system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Enkiro.Types
  alias Enkiro.Accounts
  alias Enkiro.Accounts.User
  alias Enkiro.Games.{Game, Patch}
  alias Enkiro.Content.PostDetail

  @derive {
    Flop.Schema,
    filterable: [:title, :post_type, :status, :author_id, :game_patch_id, :game_id],
    sortable: [:title, :inserted_at, :game_patch_id]
  }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "posts" do
    field :status, Ecto.Enum, values: Types.all_post_status_values()
    field :title, :string
    field :post_type, Ecto.Enum, values: Types.post_type_values()
    embeds_one :details, PostDetail, on_replace: :delete

    belongs_to :author, User, foreign_key: :author_id, type: :binary_id
    belongs_to :game_patch, Patch, type: :binary_id
    belongs_to :game, Game, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, author, attrs) do
    # First, determine the post_type from the attributes or the existing struct.
    post_type = attrs["post_type"] || attrs[:post_type] || post.post_type

    # Build the main changeset pipeline using only the main attributes.
    post
    |> cast(attrs, [:title, :status, :post_type, :game_id, :game_patch_id])
    # we do not want to override author if the post is already created and we are only updating the post
    |> maybe_put_author(author)
    |> validate_required([:title, :post_type, :author, :game_id, :game_patch_id])
    |> validate_and_default_status(author)
    |> cast_embed(:details,
      with: fn detail, details_attrs ->
        details_attrs =
          details_attrs
          |> Map.put(:post_type, post_type)
          |> Jason.encode!()
          |> Jason.decode!()

        PostDetail.changeset(detail, details_attrs)
      end
    )
  end

  def delete_post_changeset(post) do
    post
    |> change()
    |> put_change(:status, :deleted)
  end

  defp maybe_put_author(changeset, author) do
    if get_field(changeset, :author_id) do
      changeset
    else
      put_assoc(changeset, :author, author)
    end
  end

  defp validate_and_default_status(changeset, author) do
    post_type = get_field(changeset, :post_type)
    status = get_field(changeset, :status)
    is_trusted = author.reputation_tier not in [:observer, :contributor]

    allowed_statuses =
      case post_type do
        :bug_report ->
          # only staff and game studio can change the status of a bug report
          # if is staff or is game studio bug report is about then allow them to change the status
          bug_report_valid_statuses(changeset, author)

        :player_report ->
          # only trusted users and staff can change the status of a player report
          # if is the creating trusted user or is staff then allow them to change the status
          player_report_valid_statuses(changeset, author)

        :publication ->
          # only trusted users and staff can change the status of a publication
          # if is the creating trusted user or is staff then allow them to change the status
          player_report_valid_statuses(changeset, author)

        _ ->
          []
      end

    # if the user is a trusted user and they are setting the status of a post allow it
    if status do
      validate_inclusion(changeset, :status, allowed_statuses)
    else
      default_status_atom =
        case {post_type, is_trusted} do
          {:bug_report, _} -> :open
          {_, true} -> :live
          {_, false} -> :pending_review
        end

      # Convert the atom to a string before putting it in the change.
      put_change(changeset, :status, default_status_atom)
    end
  end

  defp player_report_valid_statuses(changeset, user) do
    is_admin = Accounts.user_has_role?(user, ["super_admin"])
    is_trusted = user.reputation_tier not in [:observer, :contributor]
    post_creator = get_field(changeset, :author_id)
    is_post_creator = get_field(changeset, :author_id) == user.id

    if is_admin or (is_trusted and is_post_creator) or (is_nil(post_creator) and is_trusted) do
      Types.player_report_status_values()
    else
      [:pending_review]
    end
  end

  defp bug_report_valid_statuses(_changeset, user) do
    is_admin = Accounts.user_has_role?(user, ["super_admin"])
    # Placeholder for actual game studio admin check
    is_game_studio_admin = false

    if is_admin or is_game_studio_admin do
      Types.bug_report_status_values()
    else
      [:open]
    end
  end
end
