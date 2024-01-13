defmodule MdsData.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "projects" do
    field :name, :string
    field :account_id, :binary_id
    field :creator_id, :binary_id

    has_many :resources, MdsData.Projects.Resource
    has_many :environments, MdsData.Projects.Environment
    has_many :deployments, MdsData.Deployments.Deployment

    timestamps()
  end

  @spec changeset(
          {map, map}
          | %{
              :__struct__ => atom | %{:__changeset__ => map, optional(any) => any},
              optional(atom) => any
            },
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :creator_id, :account_id])
    |> validate_required([:name, :creator_id, :account_id])
  end

  def tag(project) do
    project.name
    |> String.downcase()
    |> String.replace(~r/\s/, "-")
  end
end
