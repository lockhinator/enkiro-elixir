defmodule EnkiroWeb.ViewHelpers do
  @moduledoc """
  Provides helper functions for rendering views, especially for preloaded associations.
  """
  alias Ecto.Association.NotLoaded

  def render_many_preloaded(%NotLoaded{}, _, _, _), do: []

  def render_many_preloaded(list, view, clause, params),
    do: Enum.map(list, &render_one_preloaded(view, clause, params, &1))

  def render_one_preloaded(%NotLoaded{}, _, _, _), do: nil

  def render_one_preloaded(view, clause, params) do
    response = view.render(clause, params)

    if Map.has_key?(response, :data) do
      response.data
    else
      response
    end
  end
end
