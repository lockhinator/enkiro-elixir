defmodule Enkiro.Repo.Migrations.CreateGameStudios do
  use Ecto.Migration

  def change do
    create table(:game_studios, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :publisher_id, references(:game_publishers, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:game_studios, [:publisher_id])
  end
end
