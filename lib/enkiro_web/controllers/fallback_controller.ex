defmodule EnkiroWeb.FallbackController do
  use Phoenix.Controller

  def call(%Plug.Conn{} = conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(EnkiroWeb.FallbackControllerJSON)
    |> render("error.json", %{error: :unauthorized})
  end

  def call(%Plug.Conn{} = conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(EnkiroWeb.FallbackControllerJSON)
    |> render("error.json", changeset: changeset)
  end
end
