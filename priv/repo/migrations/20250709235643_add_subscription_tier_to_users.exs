defmodule Enkiro.Repo.Migrations.AddSubscriptionTierToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :subscription_tier, :string, null: false, default: "free"
    end
  end
end
