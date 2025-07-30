defmodule EnkiroWeb.V1.FollowControllerTest do
  use EnkiroWeb.ConnCase

  import Enkiro.GamesFixtures
  import Enkiro.AccountsFixtures

  alias Enkiro.Repo
  alias Enkiro.Accounts.UserFollow
  alias Enkiro.Guardian, as: EnkiroGuardian

  describe "index/2" do
    test "returns a list of the current users follows (no others follows)", %{conn: conn} do
      user = user_fixture()
      game = game_fixture()
      game2 = game_fixture()

      follow = user_follow_fixture(%{user_id: user.id, game_id: game.id})
      follow2 = user_follow_fixture(%{user_id: user.id, game_id: game2.id})

      user2 = user_fixture()
      user2_follow = user_follow_fixture(%{user_id: user2.id, game_id: game.id})

      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/users/me/followed_games")

      assert %{
               "data" => [
                 %{
                   "game" => %{
                     "id" => follow_game_id,
                     "title" => follow_game_title
                   },
                   "game_id" => _,
                   "id" => follow_id,
                   "inserted_at" => _,
                   "updated_at" => _,
                   "user" => %{
                     "email" => follow_user_email,
                     "id" => follow_user_id
                   },
                   "user_id" => _
                 },
                 %{
                   "game" => %{
                     "id" => follow2_game_id,
                     "title" => follow2_game_title
                   },
                   "game_id" => _,
                   "id" => follow2_id,
                   "inserted_at" => _,
                   "updated_at" => _,
                   "user" => %{
                     "email" => follow2_user_email,
                     "id" => follow2_user_id
                   },
                   "user_id" => _
                 }
               ]
             } = json_response(conn, 200)

      assert follow_id == follow.id
      assert follow_game_id == game.id
      assert follow_game_title == game.title
      assert follow_user_email == user.email
      assert follow_user_id == user.id

      assert follow2_id == follow2.id
      assert follow2_game_id == game2.id
      assert follow2_game_title == game2.title
      assert follow2_user_email == user.email
      assert follow2_user_id == user.id

      refute user2_follow.id in [follow_id, follow2_id]
    end
  end

  describe "follow/2" do
    test "creates a user follow", %{conn: conn} do
      user = user_fixture()
      game = game_fixture()

      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/v1/users/me/followed_games", %{"game_id" => game.id})

      assert %{
               "game_id" => game_id,
               "id" => follow_id,
               "user_id" => user_id
             } = json_response(conn, 201)

      assert game_id == game.id
      assert user_id == user.id
      assert follow_id

      assert %UserFollow{} = user_follow = Repo.get(UserFollow, follow_id)

      # ensure the version is recorded
      version = PaperTrail.get_version(user_follow)
      assert version.originator_id == user.id

      assert %{
               "game_id" => version_game_id,
               "user_id" => version_user_id,
               "id" => version_follow_id
             } = version.item_changes

      assert version.item_type == "UserFollow"
      assert version.event == "insert"

      assert version_game_id == game.id
      assert version_user_id == user.id
      assert version_follow_id == follow_id
    end
  end

  describe "unfollow/2" do
    test "deletes user follow", %{conn: conn} do
      user = user_fixture()
      game = game_fixture()

      follow = user_follow_fixture(%{user_id: user.id, game_id: game.id})

      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/users/me/followed_games/#{game.id}")

      assert "" = response(conn, 204)

      refute Repo.get(UserFollow, follow.id)

      # ensure the version is recorded
      version = PaperTrail.get_version(follow)
      assert version.originator_id == user.id

      assert %{
               "game_id" => version_game_id,
               "user_id" => version_user_id,
               "id" => version_follow_id
             } = version.item_changes

      assert version.item_type == "UserFollow"
      assert version.event == "delete"

      assert version_game_id == game.id
      assert version_user_id == user.id
      assert version_follow_id == follow.id
    end
  end
end
