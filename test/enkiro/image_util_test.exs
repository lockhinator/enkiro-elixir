defmodule Enkiro.ImageUtilTest do
  use Enkiro.DataCase

  @upload_folder "test_uploads"
  @upload_dir Path.join(Application.app_dir(:enkiro, "priv/static"), @upload_folder)

  describe "permanent_image_exists?/1" do
    setup do
      # Create a test image file
      File.mkdir_p!(@upload_dir)
      test_file = Path.join(@upload_dir, "test_image.png")
      File.write!(test_file, "test content")

      on_exit(fn ->
        # Cleanup after tests
        File.rm_rf!(@upload_dir)
      end)

      %{
        test_file_path: "/uploads/test_image.png",
        nonexistent_path: "/uploads/nonexistent.png"
      }
    end

    test "returns true when image exists", %{test_file_path: path} do
      assert Enkiro.ImageUtils.permanent_image_exists?(path)
    end

    test "returns false when image does not exist", %{nonexistent_path: path} do
      refute Enkiro.ImageUtils.permanent_image_exists?(path)
    end

    test "returns false for nil path" do
      refute Enkiro.ImageUtils.permanent_image_exists?("not_existing.png")
    end
  end

  describe "delete_permanent_image/1" do
    test "successfully deletes existing image" do
      File.mkdir_p!(@upload_dir)
      test_file = Path.join(@upload_dir, "test_delete1.png")
      File.write!(test_file, "test content")

      assert Enkiro.ImageUtils.permanent_image_exists?(test_file)
      assert :ok = Enkiro.ImageUtils.delete_permanent_image(test_file)
      refute Enkiro.ImageUtils.permanent_image_exists?(test_file)
    end

    test "returns :ok when trying to delete non-existent image" do
      File.mkdir_p!(@upload_dir)
      test_file = Path.join(@upload_dir, "non_existant_file.png")

      assert :ok = Enkiro.ImageUtils.delete_permanent_image(test_file)
    end

    test "returns :ok when path is nil" do
      assert :ok = Enkiro.ImageUtils.delete_permanent_image(nil)
    end
  end

  describe "create_temp_from_base64/1" do
    test "successfully creates a temp file from valid Base64 string" do
      original_fixture_path = "test/fixtures/tarkov_logo.png"
      original_binary_data = File.read!(original_fixture_path)
      cover_art_data = Base.encode64(original_binary_data)
      base64_string = "data:image/png;base64,#{cover_art_data}"

      {:ok, image_type, path} = Enkiro.ImageUtils.create_temp_from_base64(base64_string)

      assert image_type == "image/png"

      assert File.read!(path) == original_binary_data

      File.rm!(path)
    end

    test "returns error for invalid Base64 string" do
      assert {:error, "invalid Base64 string supplied"} =
               Enkiro.ImageUtils.create_temp_from_base64("invalid_base64_string")
    end

    test "returns error for Base64 string without data prefix" do
      assert {:error, "invalid prefix for Base64 image string"} =
               Enkiro.ImageUtils.create_temp_from_base64("dater:image/png;base64,")
    end
  end

  describe "save_permanent_image/2" do
    test "saves a temporary image to a permanent location" do
      original_fixture_path = "test/fixtures/tarkov_logo.png"
      original_binary_data = File.read!(original_fixture_path)
      cover_art_data = Base.encode64(original_binary_data)
      base64_string = "data:image/png;base64,#{cover_art_data}"

      {:ok, image_type, temp_path} = Enkiro.ImageUtils.create_temp_from_base64(base64_string)

      assert {:ok, permanent_url} = Enkiro.ImageUtils.save_permanent_image(image_type, temp_path)

      permanent_base_path = "priv/static/#{@upload_folder}"
      permanent_file_path = "#{permanent_base_path}/#{Path.basename(permanent_url)}"

      assert permanent_url =~ "/#{@upload_folder}/"
      assert permanent_url =~ ".png"

      assert File.exists?(permanent_file_path)
      assert File.read!(permanent_file_path) == original_binary_data

      File.rm(temp_path)
      File.rm!(permanent_file_path)
    end
  end
end
