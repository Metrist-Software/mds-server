defmodule MdsData.Repo.Migrations.CreateApiKeys do
  use Ecto.Migration

  def change do
    create table(:api_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :key, :string
      add :scope, :string
      add :scope_id, :string

      timestamps()
    end
  end
end
