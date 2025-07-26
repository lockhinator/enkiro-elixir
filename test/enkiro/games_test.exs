defmodule Enkiro.GamesTest do
  use Enkiro.DataCase

  import Enkiro.AccountsFixtures
  import Enkiro.GamesFixtures

  alias Enkiro.Games

  describe "user_create_game/1" do
    test "creates game with slug" do
      user = user_fixture()

      {:ok, %{version: version, model: game}} =
        Games.user_create_game(user, %{
          title: "Test Game",
          genre: "Action",
          release_date: ~D[2023-10-01],
          status: "released",
          ai_overview: "AI overview text",
          publisher_overview: "Publisher overview text",
          logo_path: "/path/to/logo.png",
          cover_art_path: "/path/to/cover.png",
          store_url: "http://example.com/store/test-game",
          steam_appid: 123_456
        })

      assert game.slug == "test-game"
      assert game.title == "Test Game"
      assert game.genre == "Action"
      assert game.release_date == ~D[2023-10-01]
      assert game.status in Enkiro.Games.Game.game_statuses()
      assert game.ai_overview == "AI overview text"
      assert game.publisher_overview == "Publisher overview text"
      assert game.logo_path == "/path/to/logo.png"
      assert game.cover_art_path == "/path/to/cover.png"
      assert game.store_url == "http://example.com/store/test-game"
      assert game.steam_appid == 123_456

      assert version.originator_id == user.id

      assert %{
               title: version_title
             } = version.item_changes

      assert version_title == "Test Game"
    end

    test "fails to create game with missing required fields" do
      assert {:error, changeset} = Games.create_game(%{title: "Incomplete Game"})
      assert changeset.valid? == false
      assert changeset.errors[:genre] != nil
      assert changeset.errors[:release_date] != nil
      assert changeset.errors[:status] != nil
      assert changeset.errors[:ai_overview] != nil
      assert changeset.errors[:publisher_overview] != nil
      assert changeset.errors[:logo_path] != nil
      assert changeset.errors[:cover_art_path] != nil
      assert changeset.errors[:store_url] != nil
      assert changeset.errors[:steam_appid] != nil
    end
  end

  describe "user_update_game/2" do
    test "updates game attributes" do
      user = user_fixture()

      {:ok, game} =
        Games.create_game(%{
          title: "Old Game",
          genre: "Adventure",
          release_date: ~D[2023-01-01],
          status: Enum.random(Enkiro.Games.Game.game_statuses()),
          ai_overview: "Old AI overview",
          publisher_overview: "Old Publisher overview",
          logo_path: "/old/logo.png",
          cover_art_path: "/old/cover.png",
          store_url: "http://example.com/store/old-game",
          steam_appid: 654_321
        })

      assert game.title == "Old Game"
      assert game.genre == "Adventure"

      {:ok, %{version: version, model: updated_game}} =
        Games.user_update_game(user, game, %{title: "Updated Game", genre: "RPG"})

      assert updated_game.title == "Updated Game"
      assert updated_game.genre == "RPG"
      assert version.originator_id == user.id

      assert %{
               title: version_title
             } = version.item_changes

      assert version_title == updated_game.title
    end

    test "fails to update game with invalid attributes" do
      user = user_fixture()
      game = game_fixture()

      assert {:error, changeset} = Games.user_update_game(user, game, %{title: nil})
      assert changeset.valid? == false
      assert changeset.errors[:title] == {"can't be blank", [validation: :required]}
    end
  end

  describe "get_game/1" do
    test "retrieves game by ID" do
      {:ok, game} =
        Games.create_game(%{
          title: "Retrieve Game",
          genre: "Puzzle",
          release_date: ~D[2023-09-01],
          status: "released",
          ai_overview: "Retrieve AI overview",
          publisher_overview: "Retrieve Publisher overview",
          logo_path: "/retrieve/logo.png",
          cover_art_path: "/retrieve/cover.png",
          store_url: "http://example.com/store/retrieve-game",
          steam_appid: 345_678
        })

      retrieved_game = Games.get_game(game.id)
      assert retrieved_game.id == game.id
      assert retrieved_game.title == "Retrieve Game"
    end
  end

  describe "get_game_by/2" do
    test "retrieves game by attributes" do
      {:ok, game} =
        Games.create_game(%{
          title: "Find Game",
          genre: "Simulation",
          release_date: ~D[2023-08-01],
          status: "released",
          ai_overview: "Find AI overview",
          publisher_overview: "Find Publisher overview",
          logo_path: "/find/logo.png",
          cover_art_path: "/find/cover.png",
          store_url: "http://example.com/store/find-game",
          steam_appid: 456_789
        })

      found_game = Games.get_game_by(%{title: "Find Game"})
      assert found_game.id == game.id
      assert found_game.title == "Find Game"
    end
  end

  describe "list_games/1" do
    test "lists all games" do
      {:ok, _game1} =
        Games.create_game(%{
          title: "Game 1",
          genre: "Action",
          release_date: ~D[2023-10-01],
          status: "released",
          ai_overview: "AI 1",
          publisher_overview: "Publisher 1",
          logo_path: "/logo1.png",
          cover_art_path: "/cover1.png",
          store_url: "http://example.com/store/game1",
          steam_appid: 123_456
        })

      {:ok, _game2} =
        Games.create_game(%{
          title: "Game 2",
          genre: "Adventure",
          release_date: ~D[2023-10-02],
          status: "released",
          ai_overview: "AI 2",
          publisher_overview: "Publisher 2",
          logo_path: "/logo2.png",
          cover_art_path: "/cover2.png",
          store_url: "http://example.com/store/game2",
          steam_appid: 654_321
        })

      {games, %Flop.Meta{opts: [for: Enkiro.Games.Game, replace_invalid_params: true]}} =
        Games.list_games()

      assert length(games) >= 2
    end

    test "filters games by genre" do
      {:ok, _game1} =
        Games.create_game(%{
          title: "Action Game",
          genre: "Action",
          release_date: ~D[2023-10-01],
          status: "released",
          ai_overview: "AI 1",
          publisher_overview: "Publisher 1",
          logo_path: "/logo1.png",
          cover_art_path: "/cover1.png",
          store_url: "http://example.com/store/action-game",
          steam_appid: 123_456
        })

      {:ok, _game2} =
        Games.create_game(%{
          title: "Adventure Game",
          genre: "Adventure",
          release_date: ~D[2023-10-02],
          status: "released",
          ai_overview: "AI 2",
          publisher_overview: "Publisher 2",
          logo_path: "/logo2.png",
          cover_art_path: "/cover2.png",
          store_url: "http://example.com/store/adventure-game",
          steam_appid: 654_321
        })

      {
        games,
        %Flop.Meta{
          current_page: 1,
          total_count: 1,
          total_pages: 1,
          flop: %Flop{
            filters: [%Flop.Filter{field: :genre, op: :ilike_and, value: "Action"}]
          },
          opts: [
            for: Enkiro.Games.Game,
            replace_invalid_params: true
          ]
        }
      } = Games.list_games(%{filters: [%{field: :genre, op: :ilike_and, value: "Action"}]})

      assert length(games) == 1
      assert hd(games).title == "Action Game"
    end

    test "filters games by title" do
      {:ok, _game1} =
        Games.create_game(%{
          title: "Action Game",
          genre: "Action",
          release_date: ~D[2023-10-01],
          status: "released",
          ai_overview: "AI 1",
          publisher_overview: "Publisher 1",
          logo_path: "/logo1.png",
          cover_art_path: "/cover1.png",
          store_url: "http://example.com/store/action-game",
          steam_appid: 123_456
        })

      {:ok, _game2} =
        Games.create_game(%{
          title: "Adventure Game",
          genre: "Adventure",
          release_date: ~D[2023-10-02],
          status: "released",
          ai_overview: "AI 2",
          publisher_overview: "Publisher 2",
          logo_path: "/logo2.png",
          cover_art_path: "/cover2.png",
          store_url: "http://example.com/store/adventure-game",
          steam_appid: 654_321
        })

      {
        games,
        %Flop.Meta{
          current_page: 1,
          total_count: 1,
          total_pages: 1,
          flop: %Flop{
            filters: [%Flop.Filter{field: :title, op: :ilike_and, value: "Adventure Game"}]
          },
          opts: [
            for: Enkiro.Games.Game,
            replace_invalid_params: true
          ]
        }
      } =
        Games.list_games(%{filters: [%{field: :title, op: :ilike_and, value: "Adventure Game"}]})

      assert length(games) == 1
      assert hd(games).title == "Adventure Game"
    end
  end

  describe "user_delete_game/2" do
    test "deletes a game" do
      user = user_fixture()

      {:ok, game} =
        Games.create_game(%{
          title: "Delete Game",
          genre: "Horror",
          release_date: ~D[2023-07-01],
          status: "released",
          ai_overview: "Delete AI overview",
          publisher_overview: "Delete Publisher overview",
          logo_path: "/delete/logo.png",
          cover_art_path: "/delete/cover.png",
          store_url: "http://example.com/store/delete-game",
          steam_appid: 987_654
        })

      assert {:ok, _deleted_game} = Games.user_delete_game(user, game)
      assert Games.get_game(game.id) == nil
      version = PaperTrail.get_version(game)
      assert version.originator_id == user.id
      assert version.event == "delete"
    end
  end

  describe "list_publishers/1" do
    test "lists all publishers" do
      {:ok, _publisher1} =
        Games.create_publisher(%{name: "Publisher 1", website: "http://publisher1.com"})

      {:ok, _publisher2} =
        Games.create_publisher(%{name: "Publisher 2", website: "http://publisher2.com"})

      publishers = Games.list_publishers()
      assert length(publishers) >= 2
    end
  end

  describe "create_publisher/1" do
    test "creates a publisher" do
      {:ok, publisher} = Games.create_publisher(%{name: "New Publisher"})
      assert publisher.name == "New Publisher"
    end

    test "fails to create publisher with missing required fields" do
      assert {:error, changeset} = Games.create_publisher(%{name: nil})
      assert changeset.valid? == false
      assert changeset.errors[:name] != nil
    end
  end

  describe "update_publisher/2" do
    test "updates publisher attributes" do
      {:ok, publisher} = Games.create_publisher(%{name: "Old Publisher"})
      assert publisher.name == "Old Publisher"

      {:ok, updated_publisher} = Games.update_publisher(publisher, %{name: "Updated Publisher"})
      assert updated_publisher.name == "Updated Publisher"
    end

    test "fails to update publisher with invalid attributes" do
      {:ok, publisher} = Games.create_publisher(%{name: "Valid Publisher"})
      assert {:error, changeset} = Games.update_publisher(publisher, %{name: nil})
      assert changeset.valid? == false
      assert changeset.errors[:name] == {"can't be blank", [validation: :required]}
    end
  end

  describe "get_publisher/1" do
    test "retrieves publisher by ID" do
      {:ok, publisher} = Games.create_publisher(%{name: "Retrieve Publisher"})
      retrieved_publisher = Games.get_publisher(publisher.id)
      assert retrieved_publisher.id == publisher.id
      assert retrieved_publisher.name == "Retrieve Publisher"
    end
  end

  describe "delete_publisher/1" do
    test "deletes a publisher" do
      {:ok, publisher} = Games.create_publisher(%{name: "Delete Publisher"})
      assert {:ok, _deleted_publisher} = Games.delete_publisher(publisher)
      assert Games.get_publisher(publisher.id) == nil
    end
  end

  describe "list_studios/1" do
    test "lists all studios" do
      {:ok, _studio1} = Games.create_studio(%{name: "Studio 1"})
      {:ok, _studio2} = Games.create_studio(%{name: "Studio 2"})

      studios = Games.list_studios()
      assert length(studios) >= 2
    end
  end

  describe "create_studio/1" do
    test "creates a studio" do
      {:ok, studio} = Games.create_studio(%{name: "New Studio"})
      assert studio.name == "New Studio"
    end

    test "fails to create studio with missing required fields" do
      assert {:error, changeset} = Games.create_studio(%{name: nil})
      assert changeset.valid? == false
      assert changeset.errors[:name] != nil
    end
  end
end
