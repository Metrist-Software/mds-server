defmodule MdsData.Deployments do
  @moduledoc """
  The Deployments context.
  """

  import Ecto.Query, warn: false
  alias MdsData.Repo

  alias MdsData.Deployments.Deployment

  def list_deployments do
    Repo.all(Deployment)
  end

  def list_deployments(project, env) do
    query =
      from d in Deployment,
        where:
          d.project_id == ^project.id and
            d.environment_id == ^env.id,
        order_by: [desc: d.updated_at]

    Repo.all(query)
  end

  def get_deployment!(id), do: Repo.get!(Deployment, id)

  def last_deployment(project) do
    query =
      from d in Deployment,
        where: d.project_id == ^project.id,
        order_by: [desc: d.updated_at],
        limit: 1

    Repo.one(query)
  end


  def last_deployment(project, env) do
    query =
      from d in Deployment,
        where:
          d.project_id == ^project.id and
            d.environment_id == ^env.id,
        order_by: [desc: d.updated_at],
        limit: 1

    Repo.one(query)
  end


  def last_deployment_state(project, env) do
    query =
      from d in Deployment,
        where:
          d.project_id == ^project.id and
            d.environment_id == ^env.id and
            not is_nil(d.state_data),
        order_by: [desc: d.updated_at],
        select: d.state_data,
        limit: 1

    Repo.one(query)
  end

  def create_deployment(project, env, kind, source, source_id, tag \\ nil) do
    %Deployment{
      project_id: project.id,
      environment_id: env.id,
      kind: kind,
      source: source,
      source_id: source_id,
      state: :new,
      tag: tag
    }
    |> Repo.insert()
  end

  def full_preload_deployment(deployment) do
    Repo.preload(deployment, project: [:resources], environment: [])
  end

  def update_deployment(%Deployment{} = deployment, attrs) do
    deployment
    |> Deployment.changeset(attrs)
    |> Repo.update()
  end

  def delete_deployment(%Deployment{} = deployment) do
    Repo.delete(deployment)
  end

  def delete_all_deployment_by_environment_id(env_id) do
    from(d in Deployment, where: d.environment_id == ^env_id)
    |> Repo.delete_all()
  end

  def change_deployment(%Deployment{} = deployment, attrs \\ %{}) do
    Deployment.changeset(deployment, attrs)
  end

  def add_to_log(deployment_id, log_lines) do
    # We probably want this some place else that is not a database array, but on the
    # other hand, the logs shouldn't grow enormously big for now.
    Repo.transaction(fn ->
      deployment = get_deployment!(deployment_id)
      update_deployment(deployment, %{log: (deployment.log || []) ++ log_lines})
    end)
  end

  alias MdsData.Deployments.ResourceState

  def list_resource_states do
    Repo.all(ResourceState)
  end

  def get_resource_state!(id), do: Repo.get!(ResourceState, id)

  def get_resource_state(resource, environment) do
    query =
      from rs in ResourceState,
        where:
          rs.resource_id == ^resource.id and
            rs.environment_id == ^environment.id

    Repo.one(query)
  end

  def upsert_resource_state(resource, deployment, state_values, decrypt_fn, encrypt_fn) do
    case get_resource_state(resource, deployment.environment) do
      nil ->
        %ResourceState{
          result: "ok",
          state_values: encrypt_fn.(state_values),
          deployment_id: deployment.id,
          resource_id: resource.id,
          environment_id: deployment.environment.id
        }
        |> Repo.insert()

      rs ->
        new_state_values =
          rs.state_values
          |> decrypt_fn.()
          |> Map.merge(state_values)
          |> encrypt_fn.()
        rs
        |> Ecto.Changeset.change(state_values: new_state_values)
        |> Repo.update()
    end
  end

  def update_resource_state(%ResourceState{} = resource_state, attrs) do
    resource_state
    |> ResourceState.changeset(attrs)
    |> Repo.update()
  end

  def delete_resource_state(%ResourceState{} = resource_state) do
    Repo.delete(resource_state)
  end

  def change_resource_state(%ResourceState{} = resource_state, attrs \\ %{}) do
    ResourceState.changeset(resource_state, attrs)
  end
end
