defmodule Enkiro.Reddit.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "reddit_posts" do
    field :title, :string
    field :author, :string
    field :body, :string
    field :url, :string
    field :reddit_id, :string
    field :posted_at, :utc_datetime
    field :permalink, :string
    field :comment_count, :integer
    field :score, :integer
    field :upvote_ratio, :float
    field :is_video, :boolean, default: false
    field :is_text_post, :boolean, default: false
    field :flair, :string
    field :thumbnail_url, :string
    field :raw_data, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:reddit_id, :title, :author, :posted_at, :permalink, :body, :url, :comment_count, :score, :upvote_ratio, :is_video, :is_text_post, :flair, :thumbnail_url, :raw_data])
    |> validate_required([:reddit_id, :title, :author, :posted_at, :permalink, :body, :url, :comment_count, :score, :upvote_ratio, :is_video, :is_text_post, :flair, :thumbnail_url])
    |> unique_constraint(:reddit_id)
  end
end
