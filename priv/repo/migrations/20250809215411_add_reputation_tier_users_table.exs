defmodule Enkiro.Repo.Migrations.AddReputationTierUsersTable do
  use Ecto.Migration

  def up do
    # Define the list of enum values from your Types module
    values = [
      "observer",
      "contributor",
      "reporter",
      "analyst",
      "veteran_analyst",
      "community_pillar"
    ]

    # Create the enum type in PostgreSQL
    execute "CREATE TYPE reputation_tier_enum AS ENUM (#{Enum.map_join(values, ",", &"'#{&1}'")})"

    # Add the column using the new enum type
    alter table(:users) do
      add :all_time_rp, :integer, null: false, default: 0
      add :reputation_tier, :reputation_tier_enum, null: false, default: "observer"
    end
  end

  def down do
    # First, remove the column that depends on the type
    alter table(:users) do
      remove :all_time_rp
      remove :reputation_tier
    end

    # Then, drop the enum type itself
    execute "DROP TYPE reputation_tier_enum"
  end
end
