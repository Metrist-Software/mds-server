defmodule MdsData.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias MdsData.Repo

  alias MdsData.Projects.Project

  def get_project(id, preloads \\ []) do
    Repo.get(Project, id)
    |> Repo.preload(preloads)
  end

  def get_project!(id, preloads \\ []) do
    Repo.get!(Project, id)
    |> Repo.preload(preloads)
  end

  def get_projects_by_account(account, preloads \\ []) do
    (from p in Project,
      where: p.account_id == ^account.id,
      preload: ^preloads)
    |> Repo.all()
  end

  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  alias MdsData.Projects.Resource

  def list_resources(%Project{} = project) do
    Repo.all(Ecto.assoc(project, :resources))
  end

  def get_resource!(id), do: Repo.get!(Resource, id)

  def create_resource(attrs \\ %{}) do
    %Resource{}
    |> Resource.changeset(attrs)
    |> Repo.insert()
  end

  def update_resource(%Resource{} = resource, attrs) do
    resource
    |> Resource.changeset(attrs)
    |> Repo.update()
  end

  def delete_resource(%Resource{} = resource) do
    Repo.delete(resource)
  end

  def delete_all_resources_by_project_id(project_id) do
    from(r in Resource, where: r.project_id == ^project_id)
    |> Repo.delete_all()
  end

  def change_resource(%Resource{} = resource, attrs \\ %{}) do
    Resource.changeset(resource, attrs)
  end

  alias MdsData.Projects.Environment

  def list_environments(%Project{} = project) do
    Repo.all(Ecto.assoc(project, :environments))
  end

  def get_environment!(id), do: Repo.get!(Environment, id)
  def get_environment(id), do: Repo.get(Environment, id)

  def create_environment(attrs \\ %{}) do
    %Environment{}
    |> Environment.changeset(attrs)
    |> Repo.insert()
  end

  def update_environment(%Environment{} = environment, attrs) do
    environment
    |> Environment.changeset(attrs)
    |> Repo.update()
  end

  def delete_environment(%Environment{} = environment) do
    Repo.delete(environment)
  end

  def change_environment(%Environment{} = environment, attrs \\ %{}) do
    Environment.changeset(environment, attrs)
  end
end
