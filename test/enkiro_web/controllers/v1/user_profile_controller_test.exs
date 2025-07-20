defmodule EnkiroWeb.V1.UserProfileControllerTest do
  use EnkiroWeb.ConnCase

  import Enkiro.AccountsFixtures

  alias Enkiro.Guardian, as: EnkiroGuardian
  alias Enkiro.Accounts

  describe "show/2" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "returns the current user when authenticated - /me endpoint", %{conn: conn, user: user} do
      # 1. Create a token for our user, just like the login controller would.
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)

      # 3. Make the request to the endpoint.
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/v1/users/me")

      assert %{
               "data" => %{
                 "id" => user_id,
                 "email" => user_email,
                 "gamer_tag" => gamer_tag,
                 "subscription_tier" => subscription_tier
               }
             } = json_response(conn, 200)

      assert user_id == user.id
      assert user_email == user.email
      assert gamer_tag == user.gamer_tag
      assert subscription_tier == "#{user.subscription_tier}"
      assert Guardian.Plug.current_resource(conn) == user
    end

    test "returns unauthorized when not authenticated - /me endpoint", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/users/me")

      assert json_response(conn, 401) == %{
               "error" => %{"message" => "Unauthorized", "status" => 401}
             }
    end
  end

  describe "update_me/2" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "updates the current user when authenticated - /me endpoint", %{conn: conn, user: user} do
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, token_type: :access)

      new_gamer_tag = "NewGamerTag"

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/v1/users/me", %{"user" => %{"gamer_tag" => new_gamer_tag}})

      assert %{
               "data" => %{
                 "id" => updated_user_id,
                 "email" => updated_user_email,
                 "gamer_tag" => updated_new_gamer_tag,
                 "subscription_tier" => user_subscription_tier
               }
             } = json_response(conn, 200)

      assert updated_user_id == user.id
      assert updated_user_email == user.email
      assert updated_new_gamer_tag == new_gamer_tag
      assert user_subscription_tier == "#{user.subscription_tier}"

      updated_user = Accounts.get_user!(user.id)
      assert updated_user.id == user.id
      assert updated_user.email == user.email
      assert updated_user.gamer_tag == new_gamer_tag
      assert updated_user.subscription_tier == user.subscription_tier
    end

    test "returns unauthorized when not authenticated - /me endpoint", %{conn: conn} do
      conn = put(conn, ~p"/api/v1/users/me", %{"user" => %{"gamer_tag" => "NewGamerTag"}})

      assert json_response(conn, 401) == %{
               "error" => %{"message" => "Unauthorized", "status" => 401}
             }
    end
  end
end
