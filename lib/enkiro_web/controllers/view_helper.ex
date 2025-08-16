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

  def render_flop_meta(%Flop.Meta{} = meta) do
    %{
      current_page: meta.current_page,
      end_cursor: meta.end_cursor,
      next_page: meta.next_page,
      page_size: meta.page_size,
      previous_page: meta.previous_page,
      start_cursor: meta.start_cursor,
      total_count: meta.total_count,
      total_pages: meta.total_pages,
      has_next_page: meta.has_next_page?,
      has_previous_page: meta.has_previous_page?
    }
  end
end
