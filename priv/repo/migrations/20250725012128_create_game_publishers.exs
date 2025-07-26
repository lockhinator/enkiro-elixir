defmodule Enkiro.Repo.Migrations.CreateGamePublishers do
  use Ecto.Migration

  def change do
    create table(:game_publishers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
