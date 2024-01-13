defmodule MdsData.Deployments.ResourceState do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "resource_states" do
    # TODO do we need this?
    field :result, :string
    field :state_values, :map

    belongs_to :deployment, MdsData.Deployments.Deployment
    belongs_to :resource, MdsData.Projects.Resource
    belongs_to :environment, MdsData.Projects.Environment

    timestamps()
  end

  @doc false
  def changeset(resource_state, attrs) do
    resource_state
    |> cast(attrs, [:result, :state_values])
    |> validate_required([:result, :state_values])
  end
end
