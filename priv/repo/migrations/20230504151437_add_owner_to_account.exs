defmodule MdsData.Repo.Migrations.AddOwnerToAccount do
  use Ecto.Migration

  def change do
    alter table("accounts") do
      add :owner_id, references(:users, on_delete: :nothing, type: :binary_id)
    end
  end
end
