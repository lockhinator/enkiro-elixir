defmodule EnkiroWeb.V1.GamesController do
  use EnkiroWeb, :controller
  alias Enkiro.Games
  alias Enkiro.Games.Game

  plug EnkiroWeb.Plugs.RoleBasedAccess, roles: [:game_create], actions: [:create]
  plug EnkiroWeb.Plugs.RoleBasedAccess, roles: [:game_edit], actions: [:update]
  plug EnkiroWeb.Plugs.RoleBasedAccess, roles: [:game_delete], actions: [:delete]

  def index(conn, params) do
    render(conn, "index.json", games: Games.list_games(params))
  end

  def create(conn, %{"game" => game_params}) do
    user = Guardian.Plug.current_resource(conn)

    with {:ok, game} <- Enkiro.Games.user_create_game(user, game_params) do
      conn
      |> put_status(:created)
      |> render("show.json", game: game)
    end
  end

  def show(conn, %{"id" => id}) do
    with {:fetch_resource, %Game{} = game} <- {:fetch_resource, Games.get_game(id)} do
      render(conn, "show.json", game: game)
    end
  end

  def show(conn, %{"slug" => slug}) do
    with {:fetch_resource, %Game{} = game} <-
           {:fetch_resource, Games.get_game_by(%{slug: slug}, [:studio])} do
      render(conn, "show.json", game: game)
    end
  end

  def update(conn, %{"id" => id, "game" => game_params}) do
    user = Guardian.Plug.current_resource(conn)

    with {:fetch_resource, %Game{} = game} <- {:fetch_resource, Games.get_game(id)},
         {:ok, updated_game} <- Games.user_update_game(user, game, game_params) do
      render(conn, "show.json", game: updated_game)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)

    with {:fetch_resource, %Game{} = game} <- {:fetch_resource, Games.get_game(id)},
         {:ok, _deleted_game} <- Games.user_delete_game(user, game) do
      send_resp(conn, :no_content, "")
    end
  end
end
