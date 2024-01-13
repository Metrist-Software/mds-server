defmodule MdsData.Repo.Migrations.IndexConstraintOnResourceState do
  use Ecto.Migration

  def change do
    create index(:resource_states, [:resource_id, :environment_id])
  end
end
