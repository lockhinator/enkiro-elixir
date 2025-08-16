defmodule EnkiroWeb.V1.ContentController do
  use EnkiroWeb, :controller

  alias Enkiro.Content

  plug EnkiroWeb.Plugs.RoleBasedAccess, roles: [:super_admin], actions: [:admin_index]

  def public_index(conn, params) do
    posts = Content.list_public_posts(params)
    render(conn, "index.json", posts: posts)
  end

  def admin_index(conn, params) do
    posts = Content.list_posts(params)
    render(conn, "index.json", posts: posts)
  end
end
