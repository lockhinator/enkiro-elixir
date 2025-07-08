defmodule EnkiroWeb.UserSessionControllerTest do
  use EnkiroWeb.ConnCase

  import Enkiro.AccountsFixtures

  alias Enkiro.Guardian, as: EnkiroGuardian

  describe "create/2" do
    test "logs the user in with valid credentials", %{conn: conn} do
      user = user_fixture()

      conn =
        post(conn, ~p"/api/users/login", user: %{email: user.email, password: "hello world!"})

      assert %{
               "data" => %{
                 "id" => user_id,
                 "email" => user_email,
                 "token" => token
               }
             } = json_response(conn, 200)

      assert user_id == user.id
      assert user_email == user.email
      assert token != nil and String.length(token) > 0
    end

    test "does not log the user in with invalid credentials", %{conn: conn} do
      user = user_fixture()

      conn =
        post(conn, ~p"/api/users/login", user: %{email: user.email, password: "valid_password"})

      assert %{"error" => %{"message" => "Invalid email or password", "status" => 401}} =
               json_response(conn, 401)
    end
  end

  describe "delete/2" do
    test "logs the user out", %{conn: conn} do
      user = user_fixture()

      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/users/logout")

      assert json_response(conn, 200) == %{"status" => 200, "message" => "Logout successful"}
    end
  end
end
