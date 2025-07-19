defmodule EnkiroWeb.V1.UserRegisterControllerTest do
  use EnkiroWeb.ConnCase

  import Enkiro.AccountsFixtures

  alias Enkiro.Accounts

  describe "create/2" do
    test "creates a user and allows login", %{conn: conn} do
      email = "test@test.com"
      password = "password123password123"

      user_params = %{
        "email" => email,
        "password" => password,
        "gamer_tag" => "gamer123"
      }

      conn = post(conn, ~p"/api/v1/users/register", user: user_params)

      assert %{
               "data" => %{
                 "email" => user_email
               }
             } = json_response(conn, 201)

      assert user_email == user_params["email"]

      # ensure we can now log in with the created user
      conn =
        build_conn()
        |> post(~p"/api/v1/users/login", user: %{email: email, password: password})

      user = Accounts.get_user_by_email(email)

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

    test "errors when invalid password supplied", %{conn: conn} do
      email = "test"
      password = "password"

      user_params = %{
        "email" => email,
        "password" => password
      }

      conn = post(conn, ~p"/api/v1/users/register", user: user_params)

      assert %{
               "errors" => %{
                 "email" => [email_error],
                 "password" => [password_error],
                 "gamer_tag" => [gamer_tag_error]
               }
             } = json_response(conn, 422)

      assert email_error == "must have the @ sign and no spaces"
      assert password_error == "should be at least 12 character(s)"
      assert gamer_tag_error == "can't be blank"
    end

    test "returns error when email and gamer tag have already been taken", %{conn: conn} do
      user = user_fixture(email: "lockhintor@gmail.com")

      email = user.email
      password = "password"

      user_params = %{
        "email" => email,
        "password" => password,
        "gamer_tag" => user.gamer_tag
      }

      conn = post(conn, ~p"/api/v1/users/register", user: user_params)

      assert %{
               "errors" => %{
                 "email" => [email_error],
                 "password" => [password_error],
                 "gamer_tag" => [gamer_tag_error]
               }
             } = json_response(conn, 422)

      assert email_error == "has already been taken"
      assert password_error == "should be at least 12 character(s)"
      assert gamer_tag_error == "has already been taken"
    end
  end
end
