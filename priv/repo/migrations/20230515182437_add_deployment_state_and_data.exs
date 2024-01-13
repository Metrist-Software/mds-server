defmodule MdsData.Repo.Migrations.AddDeploymentStateAndData do
  use Ecto.Migration

  def change do
    alter table("deployments") do
      add :state, :string
      add :state_data, :map
    end
  end
end
