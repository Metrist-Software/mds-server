defmodule MdsData.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :account_id, references(:accounts, on_delete: :nothing, type: :binary_id)
      add :creator_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:projects, [:account_id])
    create index(:projects, [:creator_id])
  end
end
