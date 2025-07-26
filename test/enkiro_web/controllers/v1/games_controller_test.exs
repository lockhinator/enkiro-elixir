defmodule EnkiroWeb.V1.GamesControllerTest do
  use EnkiroWeb.ConnCase

  import Enkiro.GamesFixtures
  import Enkiro.AccountsFixtures

  alias Enkiro.Guardian, as: EnkiroGuardian
  alias Enkiro.Accounts
  alias Enkiro.Games

  describe "index/2" do
    test "lists all games", %{conn: conn} do
      game = game_fixture()
      conn = get(conn, ~p"/api/v1/games")

      assert json_response(conn, 200)["data"] == [
               %{
                 "id" => game.id,
                 "title" => game.title,
                 "slug" => game.slug,
                 "genre" => game.genre,
                 "release_date" => "#{game.release_date}",
                 "ai_overview" => game.ai_overview,
                 "publisher_overview" => game.publisher_overview,
                 "logo_path" => game.logo_path,
                 "cover_art_path" => game.cover_art_path,
                 "store_url" => game.store_url,
                 "steam_appid" => game.steam_appid,
                 "studio_id" => game.studio_id,
                 "status" => "#{game.status}"
               }
             ]
    end
  end

  describe "show/2" do
    test "returns a game by ID", %{conn: conn} do
      game = game_fixture()
      conn = get(conn, ~p"/api/v1/games/#{game.id}")

      assert json_response(conn, 200)["data"] == %{
               "id" => game.id,
               "title" => game.title,
               "slug" => game.slug,
               "genre" => game.genre,
               "release_date" => "#{game.release_date}",
               "ai_overview" => game.ai_overview,
               "publisher_overview" => game.publisher_overview,
               "logo_path" => game.logo_path,
               "cover_art_path" => game.cover_art_path,
               "store_url" => game.store_url,
               "steam_appid" => game.steam_appid,
               "studio_id" => game.studio_id,
               "status" => "#{game.status}"
             }
    end

    test "returns 404 when game not found", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/games/12345678-1234-5678-1234-567812345678")
      assert json_response(conn, 404) == %{"errors" => [%{"base" => ["Resource not found"]}]}
    end
  end

  describe "create/2" do
    test "returns 401 when not authenticated", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/games", game: valid_game_attributes())

      assert json_response(conn, 401) == %{
               "error" => %{"message" => "Unauthorized", "status" => 401}
             }
    end

    test "returns 403 when authenticated but does not have game_create role", %{conn: conn} do
      user = user_fixture()
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/v1/games", game: valid_game_attributes())

      assert json_response(conn, 403)["error"] == "Forbidden"
    end

    test "creates a game when authenticated and has game_create role", %{conn: conn} do
      user = user_fixture()
      role = Accounts.get_role_by_name!("Game Create")
      user_role_fixture(user, role)
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)

      game_attributes = valid_game_attributes()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/v1/games", game: game_attributes)

      assert %{
               "data" => %{
                 "id" => id,
                 "title" => title,
                 "genre" => genre,
                 "release_date" => release_date,
                 "status" => status
               }
             } = json_response(conn, 201)

      game = Games.get_game(id)
      assert id == game.id
      assert title == game_attributes.title
      assert game.title == game_attributes.title
      assert game.slug == Slug.slugify(game_attributes.title, separator: "-")
      assert genre == game_attributes.genre
      assert release_date == "#{game_attributes.release_date}"
      assert status in Enum.map(Games.Game.game_statuses(), fn status -> "#{status}" end)

      version = PaperTrail.get_version(game)
      assert version.originator_id == user.id

      assert %{
               "title" => version_title
             } = version.item_changes

      assert version_title == game_attributes.title
    end

    test "returns 422 when game creation fails", %{conn: conn} do
      user = user_fixture()
      role = Accounts.get_role_by_name!("Game Create")
      user_role_fixture(user, role)
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)

      invalid_attributes = %{
        title: "",
        genre: "Invalid Genre",
        release_date: "invalid-date"
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/v1/games", game: invalid_attributes)

      assert json_response(conn, 422) == %{
               "errors" => %{
                 "ai_overview" => ["can't be blank"],
                 "cover_art_path" => ["can't be blank"],
                 "logo_path" => ["can't be blank"],
                 "publisher_overview" => ["can't be blank"],
                 "release_date" => ["is invalid"],
                 "slug" => ["can't be blank"],
                 "status" => ["can't be blank"],
                 "steam_appid" => ["can't be blank"],
                 "store_url" => ["can't be blank"],
                 "title" => ["can't be blank"]
               }
             }
    end
  end

  describe "update/2" do
    test "returns 401 when not authenticated", %{conn: conn} do
      game = game_fixture()
      conn = put(conn, ~p"/api/v1/games/#{game.id}", game: valid_game_attributes())

      assert json_response(conn, 401) == %{
               "error" => %{"message" => "Unauthorized", "status" => 401}
             }
    end

    test "returns 403 when authenticated but does not have game_edit role", %{conn: conn} do
      user = user_fixture()
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)
      game = game_fixture()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/games/#{game.id}", game: valid_game_attributes())

      assert json_response(conn, 403)["error"] == "Forbidden"
    end

    test "updates a game when authenticated and has game_edit role", %{conn: conn} do
      user = user_fixture()
      role = Accounts.get_role_by_name!("Game Edit")
      user_role_fixture(user, role)
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)
      game = game_fixture()

      updated_attributes = %{title: "Updated Game Title"}

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/games/#{game.id}", game: updated_attributes)

      assert %{
               "data" => %{
                 "id" => game_id,
                 "title" => game_title,
                 "genre" => _game_genre,
                 "release_date" => _game_release_date,
                 "status" => _game_status
               }
             } = json_response(conn, 200)

      game = Games.get_game(game.id)
      assert game_id == game.id
      assert game_title == updated_attributes.title

      version = PaperTrail.get_version(game)
      assert version.originator_id == user.id

      assert %{
               "title" => version_title
             } = version.item_changes

      assert version_title == updated_attributes.title
    end

    test "returns 404 when game not found", %{conn: conn} do
      user = user_fixture()
      role = Accounts.get_role_by_name!("Game Edit")
      user_role_fixture(user, role)
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/games/12345678-1234-5678-1234-567812345678",
          game: valid_game_attributes()
        )

      assert json_response(conn, 404) == %{"errors" => [%{"base" => ["Resource not found"]}]}
    end

    test "returns 422 when game update fails", %{conn: conn} do
      user = user_fixture()
      role = Accounts.get_role_by_name!("Game Edit")
      user_role_fixture(user, role)
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)
      game = game_fixture()

      invalid_attributes = %{title: ""}

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/games/#{game.id}", game: invalid_attributes)

      assert json_response(conn, 422) == %{
               "errors" => %{
                 "title" => ["can't be blank"]
               }
             }
    end
  end

  describe "delete/2" do
    test "returns 401 when not authenticated", %{conn: conn} do
      game = game_fixture()
      conn = delete(conn, ~p"/api/v1/games/#{game.id}")

      assert json_response(conn, 401) == %{
               "error" => %{"message" => "Unauthorized", "status" => 401}
             }
    end

    test "returns 403 when authenticated but does not have game_delete role", %{conn: conn} do
      user = user_fixture()
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)
      game = game_fixture()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/games/#{game.id}")

      assert json_response(conn, 403)["error"] == "Forbidden"
    end

    test "deletes a game when authenticated and has game_delete role", %{conn: conn} do
      user = user_fixture()
      role = Accounts.get_role_by_name!("Game Delete")
      user_role_fixture(user, role)
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)
      game = game_fixture()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/games/#{game.id}")

      assert response(conn, 204)
      assert Games.get_game(game.id) == nil

      version = PaperTrail.get_version(game)
      assert version.originator_id == user.id
      assert version.event == "delete"
    end

    test "returns 404 when game not found", %{conn: conn} do
      user = user_fixture()
      role = Accounts.get_role_by_name!("Game Delete")
      user_role_fixture(user, role)
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/games/12345678-1234-5678-1234-567812345678")

      assert json_response(conn, 404) == %{"errors" => [%{"base" => ["Resource not found"]}]}
    end
  end
end
