defmodule MdsData.Repo.Migrations.EnhanceDeploymentsTwo do
  use Ecto.Migration

  def change do
    alter table("deployments") do
      add :kind, :string
    end
  end
end
