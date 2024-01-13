defmodule MdsData.Repo.Migrations.FixApiKeyScopeId do
  use Ecto.Migration

  def change do
    alter table(:api_keys) do
      remove :scope_id
      add :scope_id, :binary_id
    end

  end
end
