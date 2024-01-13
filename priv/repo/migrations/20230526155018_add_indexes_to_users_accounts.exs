defmodule MdsData.Repo.Migrations.AddIndexesToUsersAccounts do
  use Ecto.Migration

  def change do
    create index(:users_accounts, [:user_id, :account_id], unique: true)
    create index(:users_accounts, [:account_id, :user_id], unique: true)
  end
end
