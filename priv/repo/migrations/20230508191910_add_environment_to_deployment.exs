defmodule MdsData.Repo.Migrations.AddEnvironmentToDeployment do
  use Ecto.Migration

  def change do
    alter table(:deployments) do
      add :environment_id, references(:environments, on_delete: :nothing, type: :binary_id)
    end
  end
end
