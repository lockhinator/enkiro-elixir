defmodule EnkiroWeb.Plugs.RoleBasedAccess do
  @moduledoc """
  A plug for enforcing role-based access control in Phoenix controllers.
  """
  alias Enkiro.Accounts
  alias Enkiro.Accounts.User
  import Plug.Conn

  import Phoenix.Controller, only: [action_name: 1, json: 2]

  def init(default), do: default

  def call(conn, opts) do
    current_action = action_name(conn)
    actions = Keyword.get(opts, :actions, [])
    reputation_tiers = Keyword.get(opts, :reputation_tiers, [])

    roles = Keyword.get(opts, :roles, [])
    # super admin role is always allowed
    roles =
      (roles ++ [:super_admin])
      |> Enum.map(&to_string/1)

    user = Guardian.Plug.current_resource(conn)

    has_required_role? = has_required_role?(user, roles)

    # If the user is authenticated, check if they have the required roles
    # If the user is not authenticated or does not have the required role, return an error
    cond do
      !user && current_action in actions ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized"})
        |> halt()

      current_action in actions and not Enum.member?(reputation_tiers, user.reputation_tier) and
          not has_required_role? ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Forbidden"})
        |> halt()

      true ->
        conn
    end
  end

  defp has_required_role?(%User{} = user, roles),
    do: Accounts.user_has_role?(user, roles)

  defp has_required_role?(_, _), do: false
end
