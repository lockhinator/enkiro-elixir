defmodule Enkiro.Repo.Migrations.AddGamerTagUsersTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :gamer_tag, :string, null: false
    end

    create unique_index(:users, [:gamer_tag])
  end
end
