defmodule Enkiro.Repo.Migrations.CreateVotes do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE vote_type AS ENUM ('insightful', 'upvote', 'reproduced', 'verified_fix')",
            "DROP TYPE vote_type"

    create table(:votes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :votable_id, :binary_id
      add :votable_type, :string
      add :vote_type, :vote_type, null: false
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:votes, [:user_id])
  end
end
