defmodule Enkiro.ImageUtils do
  @moduledoc """
  Utility functions for handling image processing, including Base64 decoding,
  temporary file creation, and saving images to permanent locations.
  """

  defp upload_folder do
    if Mix.env() == :test do
      "test_uploads"
    else
      "uploads"
    end
  end

  def upload_dir do
    Path.join(Application.app_dir(:enkiro, "priv/static"), upload_folder())
  end

  def permanent_image_exists?(image_path) do
    base_path = upload_dir()
    image_name = Path.basename(image_path)

    base_path
    |> Path.join(image_name)
    |> File.exists?()
  end

  def delete_permanent_image(nil), do: :ok

  def delete_permanent_image(image_path) do
    base_path = upload_dir()
    image_name = Path.basename(image_path)

    image_path = Path.join(base_path, image_name)

    # Deletes the permanent image file if it exists
    case File.exists?(image_path) do
      true -> File.rm(image_path)
      false -> :ok
    end
  end

  @doc """
  Saves a temporary image file to a permanent location and returns the public URL.
  """
  def save_permanent_image(image_type, temp_path) do
    with {:ok, extension} <- get_extension_from_image_type(image_type),
         # Generate a unique filename with the correct extension
         filename <- "#{Ecto.UUID.generate()}#{extension}",
         # Define the destination directory within priv/static
         dest_dir <- upload_dir(),
         # Ensure the directory exists
         :ok <- File.mkdir_p(dest_dir),
         # Define the full destination path
         dest_path <- Path.join(dest_dir, filename),
         # Move the file from the temp location to the permanent one
         :ok <- File.cp(temp_path, dest_path) do
      # Clean up the temporary file after a successful copy.
      File.rm(temp_path)
      # If all steps succeed, generate the public URL
      url = generate_public_url(filename)
      {:ok, url}
    else
      # Handle any errors that occurred in the with block
      {:error, :unsupported_image_type} ->
        {:error, "unsupported image type"}

      {:error, reason} ->
        # Clean up the temp file on failure to prevent clutter
        File.rm(temp_path)
        {:error, reason}
    end
  end

  @doc """
  Decodes a Base64 image string and saves it to a temporary file.

  Returns `{:ok, path_to_temp_file}` or `{:error, reason}`.
  """
  def create_temp_from_base64(base64_string) do
    with {:ok, {prefix, binary_data}} <- decode_base64(base64_string) do
      write_to_temp_file(prefix, binary_data)
    end
  end

  # Helper to decode, stripping the common data URI prefix if present
  defp decode_base64(string) when is_binary(string) do
    case String.split(string, ",", parts: 2) do
      [prefix, data] ->
        # As a safety check, ensure the prefix looks correct
        if String.starts_with?(prefix, "data:image/") do
          # The split was successful, now we can decode the data
          image_type = get_image_type_from_prefix(prefix)

          decode_with_response(image_type, data)
        else
          # It had a comma, but not the right prefix
          {:error, "invalid prefix for Base64 image string"}
        end

      _ ->
        {:error, "invalid Base64 string supplied"}
    end
  end

  defp decode_base64(_), do: {:error, "invalid input for Base64 string"}

  # Helper to create and write to a temp file
  defp write_to_temp_file(image_type, binary_data) do
    with path when is_binary(path) <- Temp.open!("temp_image_", &IO.binwrite(&1, binary_data)) do
      {:ok, image_type, path}
    end
  end

  defp get_image_type_from_prefix(prefix) do
    prefix
    |> String.trim_leading("data:")
    |> String.trim_trailing(";base64")
  end

  defp decode_with_response(prefix, binary_data) do
    with {:ok, decoded_data} <- Base.decode64(binary_data, padding: true) do
      {:ok, {prefix, decoded_data}}
    end
  end

  defp get_extension_from_image_type("image/png"), do: {:ok, ".png"}
  defp get_extension_from_image_type("image/jpeg"), do: {:ok, ".jpg"}
  defp get_extension_from_image_type("image/jpg"), do: {:ok, ".jpg"}
  defp get_extension_from_image_type("image/gif"), do: {:ok, ".gif"}
  defp get_extension_from_image_type("image/webp"), do: {:ok, ".webp"}
  defp get_extension_from_image_type(_), do: {:error, :unsupported_image_type}

  defp generate_public_url(filename) do
    Path.join(EnkiroWeb.Endpoint.url(), "/#{upload_folder()}/#{filename}")
  end
end
