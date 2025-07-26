defmodule Enkiro.Repo.Migrations.CreateUserRolesTables do
  use Ecto.Migration

  def change do
    create table(:roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :citext, null: false
      add :api_name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create table(:users_roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :role_id, references(:roles, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    index(:users_roles, [:user_id])
    index(:users_roles, [:role_id])
    create unique_index(:users_roles, [:user_id, :role_id])
    create unique_index(:roles, [:api_name])

    # Insert initial roles directly in the migration
    execute """
    INSERT INTO roles (id, name, api_name, inserted_at, updated_at)
    VALUES
      (gen_random_uuid(), 'Super Admin', 'super_admin', NOW(), NOW()),
      (gen_random_uuid(), 'Game Create', 'game_create', NOW(), NOW()),
      (gen_random_uuid(), 'Game Edit', 'game_edit', NOW(), NOW()),
      (gen_random_uuid(), 'Game Delete', 'game_delete', NOW(), NOW())
    """
  end
end
