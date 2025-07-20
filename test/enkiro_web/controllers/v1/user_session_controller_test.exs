defmodule EnkiroWeb.V1.UserSessionControllerTest do
  use EnkiroWeb.ConnCase

  import Enkiro.AccountsFixtures

  alias Enkiro.Guardian, as: EnkiroGuardian

  describe "create/2" do
    test "logs the user in with valid credentials", %{conn: conn} do
      user = user_fixture()

      conn =
        post(conn, ~p"/api/v1/users/login", user: %{email: user.email, password: "hello world!"})

      assert %{
               "data" => %{
                 "id" => user_id,
                 "email" => user_email,
                 "access_token" => access_token
               }
             } = json_response(conn, 200)

      assert user_id == user.id
      assert user_email == user.email
      refute is_nil(access_token)

      assert "enkiro_refresh=" <> _cookie_value =
               get_resp_header(conn, "set-cookie") |> Enum.at(0)

      assert get_resp_header(conn, "set-cookie") |> Enum.at(0) |> String.contains?("HttpOnly")
      assert get_resp_header(conn, "set-cookie") |> Enum.at(0) |> String.contains?("path=/")
      assert get_resp_header(conn, "set-cookie") |> Enum.at(0) |> String.contains?("SameSite=Lax")
    end

    test "does not log the user in with invalid credentials", %{conn: conn} do
      user = user_fixture()

      conn =
        post(conn, ~p"/api/v1/users/login",
          user: %{email: user.email, password: "valid_password"}
        )

      assert %{"errors" => %{"message" => "Invalid email or password", "status" => 401}} =
               json_response(conn, 401)
    end
  end

  describe "refresh/2" do
    test "issues a new access token when a valid refresh cookie is provided", %{conn: conn} do
      user = user_fixture()

      {:ok, refresh_token, _claims} =
        EnkiroGuardian.encode_and_sign(user, %{}, token_type: :refresh)

      conn =
        conn
        |> put_req_cookie("enkiro_refresh", refresh_token)
        |> post(~p"/api/v1/users/refresh")

      # The rest of your assertions are correct and will now pass.
      assert conn.status == 200, "Expected status 200 but got #{conn.status}"

      assert [header] = get_resp_header(conn, "authorization")
      assert "Bearer " <> new_access_token = header
      assert is_binary(new_access_token)
      assert String.length(new_access_token) > 0
    end

    test "returns unauthorized when no refresh cookie is provided", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/users/refresh")
      assert response(conn, 401)
    end
  end

  describe "delete/2" do
    test "logs the user out and clears the cookie", %{conn: conn} do
      user = user_fixture()
      {:ok, token, _claims} = EnkiroGuardian.encode_and_sign(user, %{}, token_type: :access)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/users/logout")

      assert json_response(conn, 200) == %{"message" => "Logout successful"}

      # --- This part of your test can remain the same ---
      cleared_cookie_header = get_resp_header(conn, "set-cookie") |> Enum.at(0)
      assert String.contains?(cleared_cookie_header, "enkiro_refresh=;")
      assert String.contains?(cleared_cookie_header, "max-age=0")

      # --- FIX: Test the revoked token against a protected GET endpoint ---
      conn_after_revoked =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        # Attempt to fetch the user's profile with the now-revoked token
        |> get(~p"/api/v1/users/me")

      # Now we correctly expect a 401 Unauthorized from the Guardian pipeline
      assert response(conn_after_revoked, 401)
    end
  end
end
