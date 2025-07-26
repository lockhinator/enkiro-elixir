defmodule Enkiro.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :slug, :string
      add :genre, :string
      add :release_date, :date
      add :status, :string
      add :ai_overview, :text
      add :publisher_overview, :text
      add :logo_path, :string
      add :cover_art_path, :string
      add :store_url, :string
      add :steam_appid, :integer
      add :studio_id, references(:game_studios, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:games, [:studio_id])
  end
end
