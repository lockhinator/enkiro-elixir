defmodule Enkiro.Repo.Migrations.CreateUserFollows do
  use Ecto.Migration

  def change do
    create table(:user_follows, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :game_id, references(:games, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:user_follows, [:user_id])
    create index(:user_follows, [:game_id])
    create unique_index(:user_follows, [:user_id, :game_id], name: :user_follows_user_id_game_id_index)
  end
end
