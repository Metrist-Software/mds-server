defmodule MdsProviders.AWS.Infrastructure do
  @moduledoc """
  Top-level provider for AWS Infrastructure.
  """
  require Logger

  def gen(resource, deployment, target_dir) do
    template = __MODULE__

    assigns =
      deployment
      |> MdsCore.Deployment.std_assigns()
      |> Keyword.merge(region: deployment.environment.options["aws_region"])

    MdsCore.Deployment.expand(template, assigns, resource.id, target_dir)
  end

  # TODO we can collapse these two into one.

  def gen_for("Database", infra, database, deployment, target_dir) do
    template = Module.concat(__MODULE__, Database)
    assigns = MdsCore.Deployment.std_assigns(deployment)
    MdsCore.Deployment.expand(template, assigns, "#{infra.id}-#{database.id}", target_dir)
  end

  def gen_for("WebApp", infra, webapp, deployment, target_dir) do
    template = Module.concat(__MODULE__, WebApp)
    assigns = MdsCore.Deployment.std_assigns(deployment)
    MdsCore.Deployment.expand(template, assigns, "#{infra.id}-#{webapp.id}", target_dir)
  end
end
