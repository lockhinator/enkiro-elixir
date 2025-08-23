defmodule Enkiro.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS ltree", ""

    create table(:comments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :path, :ltree
      add :body, :text
      add :details, :map
      add :post_id, references(:posts, on_delete: :nothing, type: :binary_id)
      add :author_id, references(:users, on_delete: :nothing, type: :binary_id), null: false
      add :parent_id, references(:comments, on_delete: :nothing, type: :binary_id), null: true

      timestamps(type: :utc_datetime)
    end

    create index(:comments, [:post_id])
    create index(:comments, [:author_id])
    create index(:comments, [:parent_id])
  end
end
