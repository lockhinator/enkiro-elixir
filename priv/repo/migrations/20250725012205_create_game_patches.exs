defmodule Enkiro.Repo.Migrations.CreateGamePatches do
  use Ecto.Migration

  def change do
    create table(:game_patches, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :version_string, :string
      add :release_date, :date
      add :notes_url, :string
      add :game_id, references(:games, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:game_patches, [:game_id])
  end
end
