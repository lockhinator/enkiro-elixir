defmodule EnkiroWeb.V1.UserProfileControllerTest do
  use EnkiroWeb.ConnCase

  import Enkiro.AccountsFixtures

  alias Enkiro.Guardian, as: EnkiroGuardian

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
end
