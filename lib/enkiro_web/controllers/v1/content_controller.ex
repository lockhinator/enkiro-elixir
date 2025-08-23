defmodule EnkiroWeb.V1.ContentController do
  use EnkiroWeb, :controller

  alias Enkiro.Content
  alias Enkiro.Content.Post
  alias Enkiro.Repo
  alias Enkiro.Accounts.User

  plug EnkiroWeb.Plugs.RoleBasedAccess, roles: [:super_admin], actions: [:admin_index]

  plug EnkiroWeb.Plugs.RoleBasedAccess,
    roles: [:super_admin],
    actions: [:create, :update, :delete],
    reputation_tiers: Enkiro.Types.user_reputation_approve_post_values()

  def public_index(conn, params) do
    posts = Content.list_public_posts(params)
    render(conn, "index.json", posts: posts)
  end

  def admin_index(conn, params) do
    posts = Content.list_posts(params)
    render(conn, "index.json", posts: posts)
  end

  def create(conn, %{"post" => post_params}) do
    with {:fetch_resource, %User{} = user} <-
           {:fetch_resource, Guardian.Plug.current_resource(conn)},
         {:ok, post} <- Content.create_post(user, post_params),
         {:fetch_resource, %Post{} = post} <-
           {:fetch_resource, Repo.preload(post, [:game_patch, :game, :author])} do
      conn
      |> put_status(:created)
      |> render("post.json", post: post)
    end
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    with {:fetch_resource, %User{} = user} <-
           {:fetch_resource, Guardian.Plug.current_resource(conn)},
         {:fetch_resource, %Post{} = post} <- {:fetch_resource, Content.get_post!(id, [:author])},
         {:can_edit, true} <- {:can_edit, Content.can_edit_post?(user, post)},
         {:ok, post} <- Content.update_post(post, user, post_params) do
      post = Repo.preload(post, [:game_patch, :game, :author])

      render(conn, "post.json", post: post)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:fetch_resource, %User{} = user} <-
           {:fetch_resource, Guardian.Plug.current_resource(conn)},
         {:fetch_resource, %Post{} = post} <- {:fetch_resource, Content.get_post!(id, [:author])},
         {:can_edit, true} <- {:can_edit, Content.can_edit_post?(user, post)},
         {:ok, _post} <- Content.delete_post(post, user) do
      send_resp(conn, :no_content, "")
    end
  end
end
