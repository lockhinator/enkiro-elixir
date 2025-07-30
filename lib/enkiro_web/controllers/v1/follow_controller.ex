defmodule EnkiroWeb.V1.FollowController do
  use EnkiroWeb, :controller

  alias Enkiro.Accounts.UserFollow
  alias Enkiro.Accounts

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    follows = Accounts.user_list_followed_games(user, params)

    render(conn, "index.json", follows: follows)
  end

  def follow(conn, %{"game_id" => game_id}) do
    user = Guardian.Plug.current_resource(conn)

    with {:ok, %{model: %UserFollow{id: follow_id}}} <- Accounts.user_follow_game(user, game_id),
         {:fetch_resource, %UserFollow{} = follow} <-
           {:fetch_resource, Accounts.get_user_follow(follow_id)} do
      conn
      |> put_status(:created)
      |> render("follow.json", follow: follow)
    end
  end

  def unfollow(conn, %{"game_id" => game_id}) do
    user = Guardian.Plug.current_resource(conn)

    with {:ok, _unfollowed} <- Accounts.user_unfollow_game(user, game_id) do
      send_resp(conn, :no_content, "")
    end
  end
end
