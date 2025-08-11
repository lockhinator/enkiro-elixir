defmodule Enkiro.Repo.Migrations.CreateRpTransactions do
  use Ecto.Migration

  def change do
    # Define the enum values from your Types module
    values = [
      "submit_player_report",
      "submit_bug_report",
      "submit_publication",
      "receive_insightful_vote",
      "bug_report_reproduced",
      "verify_bug_report",
      "publication_upvoted",
      "report_featured",
      "publication_featured",
      "bug_report_fixed",
      "cast_insightful_vote",
      "referral_signup",
      "referral_commission",
      "achievement_unlocked",
      "report_flagged"
    ]

    # Create the enum type in PostgreSQL
    execute "CREATE TYPE rp_event_type AS ENUM (#{Enum.map_join(values, ",", &"'#{&1}'")})",
            "DROP TYPE rp_event_type"

    execute "CREATE TYPE rp_source_type AS ENUM ('post', 'vote', 'achievement', 'referral')",
            "DROP TYPE rp_source_type"

    create table(:rp_transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :amount, :integer
      add :event_type, :rp_event_type, null: false
      add :source_id, :binary
      add :source_type, :rp_source_type
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :game_id, references(:games, on_delete: :nothing, type: :binary_id)

      timestamps(updated_at: false, type: :utc_datetime)
    end

    create index(:rp_transactions, [:user_id])
    create index(:rp_transactions, [:game_id])
  end
end
