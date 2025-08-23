defmodule Enkiro.Content do
  @moduledoc """
  The Content context is the public API for managing posts, comments, votes,
  and reputation transactions. It handles all interactions with the database
  and integrates with PaperTrail for auditing user-driven changes.
  """
  import Ecto.Query, warn: false

  alias Enkiro.Accounts
  alias Enkiro.Repo
  alias Enkiro.Accounts.User
  alias Enkiro.Content.Post
  alias Enkiro.Content.Comment
  alias Enkiro.Content.Vote
  alias Enkiro.Content.RpTransaction
  alias Enkiro.Content.ReputationService
  alias Enkiro.Types

  def list_posts(params \\ %{}) do
    query =
      from(
        post in Post,
        join: author in assoc(post, :author),
        join: game in assoc(post, :game),
        join: patch in assoc(post, :game_patch),
        where: post.status != ^:deleted,
        preload: [author: author, game: game, game_patch: patch]
      )

    Flop.validate_and_run!(query, params, for: Post, replace_invalid_params: true)
  end

  def list_public_posts(params \\ %{}) do
    valid_post_statuses =
      Enkiro.Types.public_post_status_values()

    query =
      from(
        post in Post,
        join: author in assoc(post, :author),
        join: game in assoc(post, :game),
        join: patch in assoc(post, :game_patch),
        where: post.status in ^valid_post_statuses,
        where: post.status != ^:deleted,
        preload: [author: author, game: game, game_patch: patch]
      )

    Flop.validate_and_run!(query, params, for: Post, replace_invalid_params: true)
  end

  def get_post!(id, preloads \\ []), do: Post |> Repo.get!(id) |> Repo.preload(preloads)

  @doc """
  Determines if a user can edit a given post.

  Post authors and super admins can edit the post.
  Returns `true` if the user can edit the post, otherwise `false`.
  """
  def can_edit_post?(%User{} = user, %Post{author_id: author_id}) do
    user.id == author_id or Accounts.user_has_role?(user, [Accounts.super_admin_role()])
  end

  def can_edit_post?(_, _), do: false

  # =================================================================
  # Posts
  # =================================================================

  @doc """
  Creates a new post (Player Report, Bug Report, or Publication).

  This is a user-driven action and will be tracked by PaperTrail.
  It also triggers the initial RP transaction for creating a post.
  """
  def create_post(%User{} = author, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:post, fn repo, _ ->
      changeset = Post.changeset(%Post{}, author, attrs)
      PaperTrail.insert(changeset, originator: author, repo: repo)
    end)
    |> Ecto.Multi.run(:create_rp, fn repo, %{post: %{version: _, model: post}} ->
      # This is a system-level action, so no originator is passed.
      create_rp_transaction(repo, %{
        user_id: author.id,
        game_id: post.game_id,
        event_type: String.to_existing_atom("submit_#{post.post_type}"),
        source_id: post.id,
        source_type: :post
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{post: %{version: _, model: post}}} -> {:ok, post}
      {:error, :post, changeset, _} -> {:error, changeset}
      {:error, _, reason, _} -> {:error, reason}
    end
  end

  @doc """
  Updates an existing post.
  At this point if the post is moved from draft to live or another live status
  we will award RP to the author of the post.

  This is a user-driven action and will be tracked by PaperTrail.
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def update_post(%Post{} = original_post, %User{} = user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:moved_to_public, fn _repo, _ ->
      # can the user move the post to a public status?
      user_has_permissions? =
        Accounts.user_has_role?(user, Types.approve_post_roles()) ||
          user.reputation_tier in Types.user_reputation_approve_post_values()

      # the list of public post statuses - we remove the :open status from this list because it is for bug reports
      # and we do not want to award RP for bug reports being moved to open
      public_post_status_values =
        (Types.public_post_status_values() -- [:open]) ++
          (Types.bug_report_status_values() -- [:open])

      # if the post is moving to a public status and was not already public
      is_moving_to_public? =
        attrs[:status] in public_post_status_values and
          original_post.status not in public_post_status_values

      cond do
        is_moving_to_public? and not user_has_permissions? ->
          {:error, "You do not have permission to move this post to a public status."}

        # if the post is moving to a public status and the user has permissions
        is_moving_to_public? and user_has_permissions? ->
          {:ok, true}

        # if the post is not moving to a public status
        true ->
          {:ok, false}
      end
    end)
    |> Ecto.Multi.run(:post, fn _repo, _ ->
      original_post
      |> Post.changeset(user, attrs)
      |> PaperTrail.update(originator: user, repo: Repo)
      |> case do
        {:ok, %{model: update_post}} -> {:ok, update_post}
        {:error, changeset} -> {:error, changeset}
      end
    end)
    |> Ecto.Multi.run(:record_rp, fn repo, %{post: post, moved_to_public: moved_to_public?} ->
      should_award_rp? = should_award_rp?(post)

      if moved_to_public? and should_award_rp? do
        event_type = determine_event_type(post)

        # Post was moved to a public status, create an RP transaction
        create_rp_transaction(repo, %{
          user_id: post.author_id,
          game_id: post.game_id,
          event_type: event_type,
          source_id: post.id,
          source_type: :post
        })
      else
        # No RP transaction needed
        {:ok, nil}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{post: updated_post}} -> {:ok, updated_post}
      {:error, :post, changeset, _} -> {:error, changeset}
    end
  end

  defp should_award_rp?(post) do
    # only award RP if the post is a player report or publication
    # or if the post is a bug report that has been reproduced
    (post.post_type in [:player_report, :publication] and
       post.status in Types.public_post_status_values()) or
      (post.post_type == :bug_report and post.status == :reproduced)
  end

  defp determine_event_type(%Post{post_type: post_type, status: post_status}) do
    if post_type == :bug_report and post_status == :reproduced do
      :bug_report_reproduced
    else
      String.to_existing_atom("approved_#{post_type}")
    end
  end

  @doc """
  Soft-deletes a post by changing its status.

  This is a user-driven action and will be tracked by PaperTrail.
  """
  def delete_post(%Post{} = post, %User{} = user) do
    post
    |> Post.delete_post_changeset()
    |> PaperTrail.update(originator: user, repo: Repo)
    |> case do
      {:ok, %{model: updated_post}} -> {:ok, updated_post}
      {:error, changeset} -> {:error, changeset}
    end
  end

  # =================================================================
  # Comments
  # =================================================================

  @doc """
  Creates a new comment on a post.

  This is a user-driven action and will be tracked by PaperTrail.
  """
  def create_comment(%User{} = author, attrs) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> PaperTrail.insert(originator: author, repo: Repo)
    |> case do
      {:ok, %{model: comment}} -> {:ok, comment}
      {:error, changeset} -> {:error, changeset}
    end
  end

  # =================================================================
  # Votes
  # =================================================================

  @doc """
  Creates a vote and awards RP to the relevant users.

  This is a user-driven action and will be tracked by PaperTrail.
  """
  def create_vote(%User{} = voter, attrs) do
    # You would need to fetch the post/comment author from the votable_id
    # to award them RP. This is a simplified example.
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:vote, Vote.changeset(%Vote{}, attrs))
    # ... add Ecto.Multi.run steps here to award RP to the voter
    # and the author of the content being voted on.
    |> PaperTrail.insert(originator: voter, repo: Repo)
    |> case do
      {:ok, %{vote: vote}} -> {:ok, vote}
      {:error, :vote, changeset, _} -> {:error, changeset}
      {:error, _, reason, _} -> {:error, reason}
    end
  end

  # =================================================================
  # Reputation Transactions (Backend Only)
  # =================================================================

  @doc """
  Creates an RP transaction and updates the user's total RP cache.

  This is a backend-only function and is NOT tracked by PaperTrail.
  It should be called within a transaction (like Ecto.Multi).
  """
  def create_rp_transaction(repo, attrs) do
    amount = ReputationService.calculate_amount(attrs[:event_type])
    attrs_with_amount = Map.put(attrs, :amount, amount)

    with {:error, :not_found} <- rp_transaction_exists?(attrs_with_amount),
         {:ok, transaction} <-
           repo.insert(RpTransaction.changeset(%RpTransaction{}, attrs_with_amount)),
         {_, nil} <- update_user_rp_cache(repo, transaction.user_id, amount) do
      {:ok, transaction}
    else
      {:ok, %RpTransaction{} = existing_transaction} ->
        {:ok, existing_transaction}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp update_user_rp_cache(repo, user_id, amount) do
    # This uses Ecto.update_all for a direct, efficient update.
    from(u in User, where: u.id == ^user_id)
    |> repo.update_all(inc: [all_time_rp: amount])
  end

  defp rp_transaction_exists?(attrs) do
    Repo.get_by(RpTransaction, %{
      source_id: attrs[:source_id],
      source_type: attrs[:source_type],
      user_id: attrs[:user_id],
      event_type: attrs[:event_type]
    })
    |> case do
      %RpTransaction{} = existing_transaction ->
        # If a transaction already exists, we don't create a new one.
        {:ok, existing_transaction}

      nil ->
        {:error, :not_found}
    end
  end
end
