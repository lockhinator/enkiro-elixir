defmodule EnkiroWeb.V1.ContentControllerTest do
  use EnkiroWeb.ConnCase

  import Enkiro.ContentFixtures
  import Enkiro.AccountsFixtures
  import Enkiro.GamesFixtures

  alias Enkiro.Repo
  alias Enkiro.Content.Post
  alias Enkiro.Guardian, as: EnkiroGuardian

  describe "public_index/2" do
    test "returns a list of posts", %{conn: conn} do
      user = user_fixture()

      {:ok, updated_user} =
        user
        |> Enkiro.Accounts.User.update_reputation_tier_changeset(%{reputation_tier: :reporter})
        |> Repo.update()

      post1 = post_fixture(updated_user, %{status: :live, title: "First Post"})
      post2 = post_fixture(updated_user, %{status: :live, title: "Second Post"})

      conn =
        conn
        |> get(~p"/api/v1/content/posts")

      assert %{
               "data" => [
                 %{
                   "id" => post1_id,
                   "title" => post1_title,
                   "author_id" => post1_author_id,
                   "game_id" => post1_game_id
                 },
                 %{
                   "id" => post2_id,
                   "title" => post2_title,
                   "author_id" => post2_author_id,
                   "game_id" => post2_game_id
                 }
               ],
               "meta" => %{
                 "current_page" => 1,
                 "end_cursor" => nil,
                 "has_next_page" => false,
                 "has_previous_page" => false,
                 "next_page" => nil,
                 "page_size" => 50,
                 "previous_page" => nil,
                 "start_cursor" => nil,
                 "total_count" => 2,
                 "total_pages" => 1
               }
             } = json_response(conn, 200)

      assert post1_id in [to_string(post1.id), to_string(post2.id)]
      assert post1_title in [post1.title, post2.title]
      assert post1_author_id == to_string(updated_user.id)
      assert post1_game_id in [to_string(post1.game_id), to_string(post2.game_id)]
      assert post2_id in [to_string(post1.id), to_string(post2.id)]
      assert post2_title in [post1.title, post2.title]
      assert post2_author_id == to_string(updated_user.id)
      assert post2_game_id in [to_string(post1.game_id), to_string(post2.game_id)]
    end
  end

  describe "admin_index/2" do
    setup do
      user = user_fixture()
      user2 = user_fixture()

      admin = user_fixture(%{role: :super_admin})

      {:ok, updated_user} =
        user
        |> Enkiro.Accounts.User.update_reputation_tier_changeset(%{reputation_tier: :reporter})
        |> Repo.update()

      post1 = post_fixture(updated_user, %{status: :live, title: "First Post"})
      post2 = post_fixture(user2, %{title: "Second Post"})

      %{
        user1: user,
        user2: user2,
        admin: admin,
        post1: post1,
        post2: post2
      }
    end

    test "returns a list of posts for admin user", %{
      conn: conn,
      admin: admin,
      user1: user1,
      user2: user2,
      post1: post1,
      post2: post2
    } do
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(admin, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/content/admin-posts")

      assert %{
               "data" => [
                 %{
                   "id" => post1_id,
                   "title" => post1_title,
                   "author_id" => post1_author_id,
                   "game_id" => post1_game_id
                 },
                 %{
                   "id" => post2_id,
                   "title" => post2_title,
                   "author_id" => post2_author_id,
                   "game_id" => post2_game_id
                 }
               ],
               "meta" => %{
                 "current_page" => 1,
                 "end_cursor" => nil,
                 "has_next_page" => false,
                 "has_previous_page" => false,
                 "next_page" => nil,
                 "page_size" => 50,
                 "previous_page" => nil,
                 "start_cursor" => nil,
                 "total_count" => 2,
                 "total_pages" => 1
               }
             } = json_response(conn, 200)

      assert post1_id == to_string(post1.id)
      assert post1_title == post1.title
      assert post1_author_id == to_string(user1.id)
      assert post1_game_id == to_string(post1.game_id)
      assert post2_id == to_string(post2.id)
      assert post2_title == post2.title
      assert post2_author_id == to_string(user2.id)
      assert post2_game_id == to_string(post2.game_id)
    end

    test "returns 403 for non-admin user", %{conn: conn, user1: user1} do
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user1, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/content/admin-posts")

      assert json_response(conn, 403)
    end
  end

  describe "create/2" do
    test "creates a post when is admin", %{conn: conn} do
      user = user_fixture(%{role: :super_admin})
      game = game_fixture()
      game_patch = patch_fixture(game)

      {:ok, updated_user} =
        user
        |> Enkiro.Accounts.User.update_reputation_tier_changeset(%{reputation_tier: :reporter})
        |> Repo.update()

      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(updated_user, token_type: :access)

      post_params = %{
        "title" => "New Post",
        "post_type" => "publication",
        "details" => %{
          "publication_type" => "article",
          "body_markdown" => "This is a great article about game design."
        },
        "game_id" => game.id,
        "game_patch_id" => game_patch.id
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/v1/content/posts", %{"post" => post_params})

      assert %{
               "id" => post_id,
               "title" => "New Post",
               "post_type" => "publication",
               "status" => "live",
               "author_id" => author_id,
               "game_id" => game_id,
               "game_patch_id" => game_patch_id,
               "details" => %{
                 "body_markdown" => "This is a great article about game design.",
                 "hours_played" => nil,
                 "media_url" => nil,
                 "playstyle" => [],
                 "post_type" => "publication",
                 "publication_type" => "article",
                 "ratings" => %{},
                 "replication_steps" => nil,
                 "video_url" => nil
               }
             } = json_response(conn, 201)

      assert post_id
      assert author_id == to_string(updated_user.id)
      assert game_id == post_params["game_id"]
      assert game_patch_id == post_params["game_patch_id"]
    end

    test "allows trusted user to create post", %{conn: conn} do
      user = user_fixture()
      game = game_fixture()
      game_patch = patch_fixture(game)

      post_params = %{
        "title" => "New Post",
        "post_type" => "publication",
        "details" => %{
          "publication_type" => "article",
          "body_markdown" => "This is a great article about game design."
        },
        "game_id" => game.id,
        "game_patch_id" => game_patch.id
      }

      {:ok, updated_user} =
        user
        |> Enkiro.Accounts.User.update_reputation_tier_changeset(%{reputation_tier: :reporter})
        |> Repo.update()

      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(updated_user, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/v1/content/posts", %{"post" => post_params})

      assert json_response(conn, 201)
    end

    test "does NOT allow non trusted user to create post", %{conn: conn} do
      user = user_fixture()
      game = game_fixture()
      game_patch = patch_fixture(game)

      post_params = %{
        "title" => "New Post",
        "post_type" => "publication",
        "details" => %{
          "publication_type" => "article",
          "body_markdown" => "This is a great article about game design."
        },
        "game_id" => game.id,
        "game_patch_id" => game_patch.id
      }

      {:ok, updated_user} =
        user
        |> Enkiro.Accounts.User.update_reputation_tier_changeset(%{reputation_tier: :observer})
        |> Repo.update()

      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(updated_user, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/v1/content/posts", %{"post" => post_params})

      assert json_response(conn, 403)
    end

    test "returns 422 when does not contain valid data", %{conn: conn} do
      user = user_fixture()

      {:ok, updated_user} =
        user
        |> Enkiro.Accounts.User.update_reputation_tier_changeset(%{reputation_tier: :reporter})
        |> Repo.update()

      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(updated_user, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/v1/content/posts", %{"post" => %{"title" => "New Post"}})

      assert %{
               "errors" => %{
                 "post_type" => ["can't be blank"],
                 "game_patch_id" => ["can't be blank"],
                 "game_id" => ["can't be blank"]
               }
             } == json_response(conn, 422)
    end

    test "returns 403 when user is not admin", %{conn: conn} do
      user = user_fixture()
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/v1/content/posts", %{"post" => %{"title" => "New Post"}})

      assert json_response(conn, 403)
    end
  end

  describe "update/2" do
    test "allows post author to update post they created", %{conn: conn} do
      user = user_fixture()

      {:ok, updated_user} =
        user
        |> Enkiro.Accounts.User.update_reputation_tier_changeset(%{reputation_tier: :reporter})
        |> Repo.update()

      post = post_fixture(updated_user, %{status: :live, title: "First Post"})

      assert post.author_id == updated_user.id

      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/content/posts/#{post.id}", %{"post" => %{"title" => "Updated Post"}})

      assert json_response(conn, 200)
    end

    test "admin can update a post they did not create", %{conn: conn} do
      user = user_fixture()

      {:ok, updated_user} =
        user
        |> Enkiro.Accounts.User.update_reputation_tier_changeset(%{reputation_tier: :reporter})
        |> Repo.update()

      post = post_fixture(updated_user, %{status: :live, title: "First Post"})

      admin = user_fixture(%{role: :super_admin})

      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(admin, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/content/posts/#{post.id}", %{"post" => %{"title" => "Updated Post"}})

      assert json_response(conn, 200)
    end

    test "non author user cannot update a post they did not create", %{conn: conn} do
      user = user_fixture()
      user2 = user_fixture()

      {:ok, updated_user} =
        user
        |> Enkiro.Accounts.User.update_reputation_tier_changeset(%{reputation_tier: :reporter})
        |> Repo.update()

      post = post_fixture(updated_user, %{status: :live, title: "First Post"})

      assert post.author_id == updated_user.id

      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user2, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/content/posts/#{post.id}", %{"post" => %{"title" => "Updated Post"}})

      assert %{"error" => "Forbidden"} = json_response(conn, 403)
    end
  end

  describe "delete/2" do
    test "allows post author to delete post they created", %{conn: conn} do
      user = user_fixture()

      {:ok, updated_user} =
        user
        |> Enkiro.Accounts.User.update_reputation_tier_changeset(%{reputation_tier: :reporter})
        |> Repo.update()

      post = post_fixture(updated_user, %{status: :live, title: "First Post"})

      assert post.author_id == updated_user.id

      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/content/posts/#{post.id}")

      assert response(conn, 204)

      assert Repo.get(Post, post.id).status == :deleted
    end

    test "admin can delete a post they did not create", %{conn: conn} do
      user = user_fixture()

      {:ok, updated_user} =
        user
        |> Enkiro.Accounts.User.update_reputation_tier_changeset(%{reputation_tier: :reporter})
        |> Repo.update()

      post = post_fixture(updated_user, %{status: :live, title: "First Post"})

      admin = user_fixture(%{role: :super_admin})

      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(admin, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/content/posts/#{post.id}")

      assert response(conn, 204)

      assert Repo.get(Post, post.id).status == :deleted
    end

    test "non author user cannot delete a post they did not create", %{conn: conn} do
      user = user_fixture()
      user2 = user_fixture()

      {:ok, updated_user} =
        user
        |> Enkiro.Accounts.User.update_reputation_tier_changeset(%{reputation_tier: :reporter})
        |> Repo.update()

      post = post_fixture(updated_user, %{status: :live, title: "First Post"})

      assert post.author_id == updated_user.id

      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user2, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/content/posts/#{post.id}")

      assert %{"error" => "Forbidden"} = json_response(conn, 403)

      assert Repo.get(Post, post.id)
    end
  end
end
