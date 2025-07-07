defmodule EnkiroWeb.PageController do
  use EnkiroWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    json(conn, %{message: "Welcome to Enkiro!"})
  end
end
