defmodule MdsData.Repo.Migrations.EnhanceDeployments do
  use Ecto.Migration

  def change do
    alter table("deployments") do
      add :source, :string
      add :source_id, :string
      add :tag, :string
      add :log, {:array, :map}
    end
  end
end
