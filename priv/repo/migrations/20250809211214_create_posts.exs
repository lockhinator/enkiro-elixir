defmodule Enkiro.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE post_type AS ENUM ('player_report', 'bug_report', 'publication')",
            "DROP TYPE post_type"

    create table(:posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :post_type, :post_type, null: false
      add :title, :text
      add :details, :map
      add :status, :string
      add :author_id, references(:users, on_delete: :nothing, type: :binary_id), null: false
      add :game_id, references(:games, on_delete: :nothing, type: :binary_id), null: false

      add :game_patch_id, references(:game_patches, on_delete: :nothing, type: :binary_id),
        null: true

      timestamps(type: :utc_datetime)
    end

    create index(:posts, [:author_id])
    create index(:posts, [:game_id])
    create index(:posts, [:game_patch_id])
  end
end
