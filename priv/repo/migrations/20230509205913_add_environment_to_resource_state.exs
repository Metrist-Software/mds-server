defmodule MdsData.Repo.Migrations.AddEnvironmentToResourceState do
  use Ecto.Migration

  def change do
    alter table("resource_states") do
      add :environment_id, references(:environments, on_delete: :nothing, type: :binary_id)
    end
  end
end
