defmodule EnkiroWeb.V1.ContentControllerTest do
  use EnkiroWeb.ConnCase

  import Enkiro.ContentFixtures
  import Enkiro.AccountsFixtures

  alias Enkiro.Repo
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

      assert post1_id == to_string(post1.id)
      assert post1_title == post1.title
      assert post1_author_id == to_string(updated_user.id)
      assert post1_game_id == to_string(post1.game_id)
      assert post2_id == to_string(post2.id)
      assert post2_title == post2.title
      assert post2_author_id == to_string(updated_user.id)
      assert post2_game_id == to_string(post2.game_id)
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
end
