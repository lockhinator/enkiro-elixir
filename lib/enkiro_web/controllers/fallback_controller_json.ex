defmodule EnkiroWeb.FallbackControllerJSON do
  def render("error.json", %{error: :unauthorized}),
    do: %{errors: [%{base: ["Unauthorized"]}]}

  def render("error.json", %{changeset: changeset}) do
    errors = Ecto.Changeset.traverse_errors(changeset, &format_error/1)

    %{errors: errors}
  end

  def render("not_found.json", _assigns) do
    %{errors: [%{base: ["Resource not found"]}]}
  end

  defp format_error({msg, opts}) do
    # This is a more robust way to format error messages, as it only
    # attempts to interpolate keys that are actually present in the message.
    Regex.replace(~r"%\{(\w+)\}", msg, fn _, key ->
      opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end
end
