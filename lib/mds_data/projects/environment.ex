defmodule MdsData.Projects.Environment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "environments" do
    field :name, :string
    field :options, :map
    field :project_id, :binary_id
    field :creator_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(environment, attrs) do
    environment
    |> cast(attrs, [:name, :options, :creator_id, :project_id])
    |> validate_required([:name, :options, :creator_id, :project_id])
  end
end
