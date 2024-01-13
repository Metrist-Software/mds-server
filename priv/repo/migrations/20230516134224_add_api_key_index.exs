defmodule MdsData.Repo.Migrations.AddApiKeyIndex do
  use Ecto.Migration

  def change do
    create index(:api_keys, [:key])
  end
end
