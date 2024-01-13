defmodule MdsData.Repo.Migrations.CreateResources do
  use Ecto.Migration

  def change do
    create table(:resources, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :options, :map
      add :project_id, references(:projects, on_delete: :nothing, type: :binary_id)
      add :creator_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:resources, [:project_id])
    create index(:resources, [:creator_id])
  end
end
