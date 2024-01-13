defmodule MdsData.Repo.Migrations.MakeUsersAccountsNN do
  use Ecto.Migration

  def change do
    create table(:users_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :account_id, references(:accounts, on_delete: :nothing, type: :binary_id)

      add :creator_id, references(:users, on_delete: :nothing, type: :binary_id)
      timestamps()
    end
  end
end
