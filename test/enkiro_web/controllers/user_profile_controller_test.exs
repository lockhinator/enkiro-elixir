defmodule EnkiroWeb.UserProfileControllerTest do
  use EnkiroWeb.ConnCase

  import Enkiro.AccountsFixtures

  alias Enkiro.Guardian, as: EnkiroGuardian

  describe "show/2" do
    test "returns the current user when authenticated", %{conn: conn} do
      user = user_fixture()
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/users/profile")

      assert %{
               "data" => %{
                 "id" => user_id,
                 "email" => user_email
               }
             } = json_response(conn, 200)

      assert user_id == user.id
      assert user_email == user.email
      assert Guardian.Plug.current_resource(conn) == user
    end

    test "returns unauthorized when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/api/users/profile")

      assert json_response(conn, 401) == %{
               "error" => %{"message" => "Unauthorized", "status" => 401}
             }
    end
  end
end
