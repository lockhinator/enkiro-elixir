defmodule EnkiroWeb.FallbackController do
  use Phoenix.Controller

  def call(%Plug.Conn{} = conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(EnkiroWeb.FallbackControllerJSON)
    |> render("error.json", changeset: changeset)
  end
end
