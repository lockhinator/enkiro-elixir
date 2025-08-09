defmodule Enkiro.Repo.Migrations.CreateRedditPosts do
  use Ecto.Migration

  def change do
    create table(:reddit_posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :reddit_id, :string
      add :title, :text
      add :author, :string
      add :posted_at, :utc_datetime
      add :permalink, :string
      add :body, :text
      add :url, :string
      add :comment_count, :integer
      add :score, :integer
      add :upvote_ratio, :float
      add :is_video, :boolean, default: false, null: false
      add :is_text_post, :boolean, default: false, null: false
      add :flair, :string
      add :thumbnail_url, :string
      add :raw_data, :map

      timestamps(type: :utc_datetime)
    end

    create unique_index(:reddit_posts, [:reddit_id])
  end
end
