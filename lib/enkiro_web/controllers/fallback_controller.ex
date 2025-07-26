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

  def call(%Plug.Conn{} = conn, {:fetch_resource, nil}) do
    conn
    |> put_status(:not_found)
    |> put_view(EnkiroWeb.FallbackControllerJSON)
    |> render("not_found.json")
  end
end
