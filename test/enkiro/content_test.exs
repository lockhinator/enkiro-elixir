defmodule Enkiro.ContentTest do
  use Enkiro.DataCase, async: true

  alias Enkiro.Content
  alias Enkiro.Content.Post
  alias Enkiro.Content.RpTransaction
  alias Enkiro.Accounts
  alias Enkiro.AccountsFixtures
  import Enkiro.ContentFixtures

  @player_report_attrs %{
    post_type: :player_report,
    title: "My thoughts on the new patch",
    details: %{
      ratings: %{"gameplay_loop" => 5, "performance" => 4},
      hours_played: "100-500"
    }
  }

  @publication_attrs %{
    post_type: :publication,
    title: "A new article on game design",
    details: %{
      publication_type: :article,
      body_markdown: "This is a great article about game design."
    }
  }

  @bug_report_attrs %{
    post_type: :bug_report,
    title: "Falling through the floor on Customs",
    details: %{
      replication_steps: "1. Go to dorms..."
    }
  }

  setup do
    user = AccountsFixtures.user_fixture()
    game = Enkiro.GamesFixtures.game_fixture()
    patch = Enkiro.GamesFixtures.patch_fixture(game)
    %{user: user, game: game, patch: patch}
  end

  describe "create_post/2" do
    test "creates a player report and awards RP", %{user: user, game: game, patch: patch} do
      attrs =
        Map.merge(@player_report_attrs, %{
          game_id: game.id,
          game_patch_id: patch.id
        })

      assert {:ok, %Post{} = post} = Content.create_post(user, attrs)
      assert post.title == "My thoughts on the new patch"
      assert post.author_id == user.id
      assert post.post_type == :player_report

      assert post.details.ratings["gameplay_loop"] == 5

      # Verify RP was awarded
      assert %RpTransaction{amount: 10, event_type: :submit_player_report} =
               Repo.get_by(RpTransaction, user_id: user.id)

      updated_user = Accounts.get_user!(user.id)
      assert updated_user.all_time_rp == 10

      # Verify PaperTrail version was created
      version = PaperTrail.get_version(post)
      assert version.originator_id == user.id
    end

    test "creates a publication with a default status of :pending_review", %{
      user: user,
      game: game,
      patch: patch
    } do
      attrs =
        Map.merge(@publication_attrs, %{
          game_id: game.id,
          game_patch_id: patch.id
        })

      assert {:ok, %Post{} = post} = Content.create_post(user, attrs)
      assert post.status == :pending_review

      # Verify RP was awarded
      assert %RpTransaction{amount: 15, event_type: :submit_publication} =
               Repo.get_by(RpTransaction, user_id: user.id)

      updated_user = Accounts.get_user!(user.id)
      assert updated_user.all_time_rp == 15

      # Verify PaperTrail version was created
      version = PaperTrail.get_version(post)
      assert version.originator_id == user.id
    end

    test "creates a bug report with a default status of :open", %{
      user: user,
      game: game,
      patch: patch
    } do
      attrs =
        Map.merge(@bug_report_attrs, %{
          game_id: game.id,
          game_patch_id: patch.id
        })

      assert {:ok, %Post{} = post} = Content.create_post(user, attrs)
      assert post.status == :open

      # Verify RP was awarded
      assert %RpTransaction{amount: 20, event_type: :submit_bug_report} =
               Repo.get_by(RpTransaction, user_id: user.id)

      updated_user = Accounts.get_user!(user.id)
      assert updated_user.all_time_rp == 20

      # Verify PaperTrail version was created
      version = PaperTrail.get_version(post)
      assert version.originator_id == user.id
    end

    test "creates a post with status :pending_review for an untrusted user", %{
      game: game,
      patch: patch
    } do
      # Fixture for a new user who is still an :observer
      {:ok, untrusted_user} = Accounts.register_user(AccountsFixtures.valid_user_attributes())

      attrs =
        Map.merge(@player_report_attrs, %{
          game_id: game.id,
          game_patch_id: patch.id
        })

      assert {:ok, %Post{} = post} = Content.create_post(untrusted_user, attrs)
      assert post.status == :pending_review
    end

    test "creates a post and sets status as :live for a trusted user", %{
      user: user,
      game: game,
      patch: patch
    } do
      {:ok, trusted_user} =
        user
        |> Enkiro.Accounts.User.update_reputation_tier_changeset(%{reputation_tier: :reporter})
        |> Repo.update()

      attrs =
        Map.merge(@player_report_attrs, %{
          game_id: game.id,
          game_patch_id: patch.id,
          status: :live
        })

      assert {:ok, %Post{} = post} = Content.create_post(trusted_user, attrs)
      assert post.status == :live
    end

    test "returns an error changeset for invalid data", %{user: user} do
      # Missing title and details
      attrs = %{post_type: :player_report}
      assert {:error, %Ecto.Changeset{}} = Content.create_post(user, attrs)
    end
  end

  describe "update_post/3" do
    test "updates a post's attributes", %{user: user} do
      post = post_fixture(user)
      update_attrs = %{title: "An updated title"}

      assert {:ok, %Post{} = updated_post} = Content.update_post(post, user, update_attrs)
      assert updated_post.title == "An updated title"

      version = PaperTrail.get_version(updated_post)
      assert version.event == "update"
      assert version.item_changes["title"] == "An updated title"
    end

    test "returns an error changeset for invalid data", %{user: user} do
      post = post_fixture(user)
      # Invalid title
      update_attrs = %{title: nil}

      assert {:error, %Ecto.Changeset{}} = Content.update_post(post, user, update_attrs)
    end

    test "updates the post's status based on post type and user trust level", %{user: user} do
      post = post_fixture(user, @player_report_attrs)
      assert post.status == :pending_review

      {:ok, updated_user} =
        user
        |> Enkiro.Accounts.User.update_reputation_tier_changeset(%{reputation_tier: :reporter})
        |> Repo.update()

      assert updated_user.reputation_tier == :reporter

      # Simulate a trusted user
      update_attrs = %{status: :live}

      assert {:ok, %Post{} = updated_post} = Content.update_post(post, updated_user, update_attrs)
      assert updated_post.status == :live
    end

    test "player_report does not change author of post when updating the post status as admin (if admin updates post author is unchanged)",
         %{user: user} do
      post = post_fixture(user, @player_report_attrs)
      assert post.status == :pending_review

      admin = AccountsFixtures.user_fixture()
      role = Accounts.get_role_by_name!("Super Admin")
      AccountsFixtures.user_role_fixture(admin, role)

      assert {:ok, %Post{} = updated_post} = Content.update_post(post, admin, %{status: :live})
      assert updated_post.status == :live
      # Author should remain unchanged
      assert updated_post.author_id == user.id
    end

    test "bug_report does not change author of post when updating the post status as admin (if admin updates post author is unchanged)",
         %{user: user} do
      post = post_fixture(user, @bug_report_attrs)
      assert post.status == :open

      admin = AccountsFixtures.user_fixture()
      role = Accounts.get_role_by_name!("Super Admin")
      AccountsFixtures.user_role_fixture(admin, role)

      assert {:ok, %Post{} = updated_post} =
               Content.update_post(post, admin, %{status: :pending_fix})

      assert updated_post.status == :pending_fix
      # Author should remain unchanged
      assert updated_post.author_id == user.id
    end

    test "publication does not change author of post when updating the post status as admin (if admin updates post author is unchanged)",
         %{user: user} do
      post = post_fixture(user, @publication_attrs)
      assert post.status == :pending_review

      admin = AccountsFixtures.user_fixture()
      role = Accounts.get_role_by_name!("Super Admin")
      AccountsFixtures.user_role_fixture(admin, role)

      assert {:ok, %Post{} = updated_post} = Content.update_post(post, admin, %{status: :live})
      assert updated_post.status == :live
      # Author should remain unchanged
      assert updated_post.author_id == user.id
    end
  end

  describe "delete_post/2" do
    test "soft-deletes a post by changing its status", %{user: user} do
      post = post_fixture(user)
      assert {:ok, %Post{} = deleted_post} = Content.delete_post(post, user)
      assert deleted_post.status == :deleted
    end
  end
end
