defmodule MdsData.Repo.Migrations.AddApiKeyIndexByScopeId do
  use Ecto.Migration

  def change do
    create index(:api_keys, [:scope, :scope_id])
  end
end
