defmodule MdsData.DeploymentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MdsData.Deployments` context.
  """

  @doc """
  Generate a deployment.
  """
  def deployment_fixture(attrs \\ %{}) do
    {:ok, deployment} =
      attrs
      |> Enum.into(%{
        reason: "some reason"
      })
      |> MdsData.Deployments.create_deployment()

    deployment
  end

  @doc """
  Generate a deployment_step.
  """
  def deployment_step_fixture(attrs \\ %{}) do
    {:ok, deployment_step} =
      attrs
      |> Enum.into(%{
        action: "some action",
        details: "some details",
        status: "some status",
        step_no: 42
      })
      |> MdsData.Deployments.create_deployment_step()

    deployment_step
  end

  @doc """
  Generate a resource_state.
  """
  def resource_state_fixture(attrs \\ %{}) do
    {:ok, resource_state} =
      attrs
      |> Enum.into(%{
        result: "some result",
        state_values: %{}
      })
      |> MdsData.Deployments.create_resource_state()

    resource_state
  end
end
