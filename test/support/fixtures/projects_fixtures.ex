defmodule MdsData.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MdsData.Projects` context.
  """

  @doc """
  Generate a project.
  """
  def project_fixture(attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        account_id: "some account_id",
        creator_id: "some creator_id",
        name: "some name"
      })
      |> MdsData.Projects.create_project()

    project
  end

  @doc """
  Generate a resource.
  """
  def resource_fixture(attrs \\ %{}) do
    {:ok, resource} =
      attrs
      |> Enum.into(%{
        configuration: %{},
        name: "some name",
        tags: ["option1", "option2"],
        type: "some type"
      })
      |> MdsData.Projects.create_resource()

    resource
  end

  @doc """
  Generate a environment.
  """
  def environment_fixture(attrs \\ %{}) do
    {:ok, environment} =
      attrs
      |> Enum.into(%{
        name: "some name",
        options: %{}
      })
      |> MdsData.Projects.create_environment()

    environment
  end
end
