defmodule EnkiroWeb.PageControllerTest do
  use EnkiroWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert json_response(conn, 200) == %{"message" => "Welcome to Enkiro!"}
  end
end
