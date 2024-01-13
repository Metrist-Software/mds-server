defmodule MdsData.Repo.Migrations.CreateResourceStates do
  use Ecto.Migration

  def change do
    create table(:resource_states, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :result, :string
      add :state_values, :map
      add :deployment_id, references(:deployments, on_delete: :nothing, type: :binary_id)
      add :resource_id, references(:resources, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:resource_states, [:deployment_id])
    create index(:resource_states, [:resource_id])
  end
end
