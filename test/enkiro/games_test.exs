defmodule Enkiro.GamesTest do
  alias Enkiro.ImageUtils
  use Enkiro.DataCase

  import Enkiro.AccountsFixtures
  import Enkiro.GamesFixtures

  alias Enkiro.Games

  describe "user_create_game/1" do
    test "creates game with slug" do
      user = user_fixture()
      studio = studio_fixture()

      cover_art_data =
        "data:image/jpg;base64,#{Base.encode64(File.read!("test/fixtures/tarkov_cover_art.jpg"))}"

      logo_data =
        "data:image/png;base64,#{Base.encode64(File.read!("test/fixtures/tarkov_logo.png"))}"

      {:ok, %{version: version, model: game}} =
        Games.user_create_game(user, %{
          title: "Test Game",
          genre: "Action",
          release_date: ~D[2023-10-01],
          status: "released",
          ai_overview: "AI overview text",
          publisher_overview: "Publisher overview text",
          logo_data: logo_data,
          cover_art_data: cover_art_data,
          store_url: "http://example.com/store/test-game",
          steam_appid: 123_456,
          studio_id: studio.id
        })

      assert game.slug == "test-game"
      assert game.title == "Test Game"
      assert game.genre == "Action"
      assert game.release_date == ~D[2023-10-01]
      assert game.status in Enkiro.Games.Game.game_statuses()
      assert game.ai_overview == "AI overview text"
      assert game.publisher_overview == "Publisher overview text"
      assert game.logo_path =~ "http://localhost:4002/test_uploads/"
      assert game.cover_art_path =~ "http://localhost:4002/test_uploads/"
      assert game.store_url == "http://example.com/store/test-game"
      assert game.steam_appid == 123_456
      assert game.studio_id == studio.id

      assert version.originator_id == user.id

      assert %{
               title: version_title
             } = version.item_changes

      assert version_title == "Test Game"

      # cleanup the image files that were created
      ImageUtils.delete_permanent_image(game.logo_path)
      ImageUtils.delete_permanent_image(game.cover_art_path)
    end

    test "cleans up images that are not persisted when validation fails" do
      user = user_fixture()
      studio = studio_fixture()

      game = game_fixture(%{studio_id: studio.id})

      cover_art_data =
        "data:image/jpg;base64,#{Base.encode64(File.read!("test/fixtures/tarkov_cover_art.jpg"))}"

      logo_data =
        "data:image/png;base64,#{Base.encode64(File.read!("test/fixtures/tarkov_logo.png"))}"

      {:error,
       %Ecto.Changeset{
         errors: [
           title:
             {"has already been taken",
              [constraint: :unique, constraint_name: "games_title_index"]}
         ]
       }} =
        Games.user_create_game(user, %{
          # duplicate title to trigger validation error
          title: game.title,
          genre: "Action",
          release_date: ~D[2023-10-01],
          status: "released",
          ai_overview: "AI overview text",
          publisher_overview: "Publisher overview text",
          logo_data: logo_data,
          cover_art_data: cover_art_data,
          store_url: "http://example.com/store/test-game",
          steam_appid: 123_456,
          studio_id: studio.id
        })

      assert File.ls(ImageUtils.upload_dir()) == {:ok, []}
    end

    test "fails to create game with missing required fields" do
      assert {:error, changeset} = Games.create_game(%{title: "Incomplete Game"})
      assert changeset.valid? == false
      assert changeset.errors[:genre] != nil
      assert changeset.errors[:release_date] != nil
      assert changeset.errors[:status] != nil
      assert changeset.errors[:ai_overview] != nil
      assert changeset.errors[:publisher_overview] != nil
      assert changeset.errors[:store_url] != nil
    end

    test "returns an error when date format is incorrect" do
      assert {:error, changeset} =
               Games.create_game(%{
                 title: "Invalid Date Game",
                 genre: "Action",
                 # Invalid date format (correct is 2025-01-01)
                 release_date: "01-01-2025",
                 status: "released",
                 ai_overview: "AI overview text",
                 publisher_overview: "Publisher overview text",
                 logo_path: "/path/to/logo.png",
                 cover_art_path: "/path/to/cover.png",
                 store_url: "http://example.com/store/invalid-date-game",
                 steam_appid: 123_456
               })

      assert changeset.valid? == false

      assert changeset.errors[:release_date] ==
               {"must be in YYYY-MM-DD format", [validation: :format]}
    end
  end

  describe "user_update_game/2" do
    test "updates game attributes" do
      user = user_fixture()

      game =
        game_fixture(%{
          title: "Old Game",
          genre: "Adventure",
          steam_appid: 234_567
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
      game =
        game_fixture(%{
          title: "Retrieve Game"
        })

      retrieved_game = Games.get_game(game.id)
      assert retrieved_game.id == game.id
      assert retrieved_game.title == "Retrieve Game"
    end
  end

  describe "get_game_by/2" do
    test "retrieves game by attributes" do
      game =
        game_fixture(%{
          title: "Find Game"
        })

      found_game = Games.get_game_by(%{slug: game.slug})
      assert found_game.id == game.id
      assert found_game.title == "Find Game"
    end
  end

  describe "list_games/1" do
    test "lists all games" do
      _game1 = game_fixture()
      _game2 = game_fixture()

      {games, %Flop.Meta{opts: [for: Enkiro.Games.Game, replace_invalid_params: true]}} =
        Games.list_games()

      assert length(games) >= 2
    end

    test "filters games by genre" do
      _game1 =
        game_fixture(%{
          genre: "Action"
        })

      _game2 =
        game_fixture(%{
          genre: "Adventure"
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
      assert hd(games).genre == "Action"
    end

    test "filters games by title" do
      _game1 =
        game_fixture(%{
          title: "Action Game"
        })

      _game2 =
        game_fixture(%{
          title: "Adventure Game"
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

      game = game_fixture()

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
