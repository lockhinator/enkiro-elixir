defmodule Enkiro.Content do
  @moduledoc """
  The Content context is the public API for managing posts, comments, votes,
  and reputation transactions. It handles all interactions with the database
  and integrates with PaperTrail for auditing user-driven changes.
  """
  import Ecto.Query, warn: false

  alias Enkiro.Repo
  alias Enkiro.Accounts.User
  alias Enkiro.Content.Post
  alias Enkiro.Content.Comment
  alias Enkiro.Content.Vote
  alias Enkiro.Content.RpTransaction
  alias Enkiro.Content.ReputationService

  def list_posts(params \\ %{}) do
    query =
      from(
        post in Post,
        join: author in assoc(post, :author),
        join: game in assoc(post, :game),
        join: patch in assoc(post, :game_patch),
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
        preload: [author: author, game: game, game_patch: patch]
      )

    Flop.validate_and_run!(query, params, for: Post, replace_invalid_params: true)
  end

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

  This is a user-driven action and will be tracked by PaperTrail.
  """
  def update_post(%Post{} = post, %User{} = user, attrs) do
    post
    |> Post.changeset(user, attrs)
    |> PaperTrail.update(originator: user, repo: Repo)
    |> case do
      {:ok, %{model: updated_post}} -> {:ok, updated_post}
      {:error, changeset} -> {:error, changeset}
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

    with {:ok, transaction} <-
           repo.insert(RpTransaction.changeset(%RpTransaction{}, attrs_with_amount)),
         {_, nil} <- update_user_rp_cache(repo, transaction.user_id, amount) do
      {:ok, transaction}
    else
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp update_user_rp_cache(repo, user_id, amount) do
    # This uses Ecto.update_all for a direct, efficient update.
    from(u in User, where: u.id == ^user_id)
    |> repo.update_all(inc: [all_time_rp: amount])
  end
end
