defmodule MdsData.Repo.Migrations.AddCreatorIdToEnvironment do
  use Ecto.Migration

  def change do
    alter table(:environments) do
      add :creator_id, :binary_id
    end
  end
end
