defmodule MdsProviders.AWS.Database do
  @moduledoc """
  Top-level provider for AWS Databases.
  """

  require Logger

  def gen(resource, deployment, target_dir) do
    template = __MODULE__
    assigns = MdsCore.Deployment.std_assigns(deployment)
    MdsCore.Deployment.expand(template, assigns, resource.id, target_dir)
  end

  def gen_for("WebApp", db, webapp, deployment, target_dir) do
    # Allow webapp sg to talk to us
    template = Module.concat(__MODULE__, WebApp)

    assigns =
      deployment
      |> MdsCore.Deployment.std_assigns()
      |> Keyword.merge(region: deployment.environment.options["aws_region"])

    MdsCore.Deployment.expand(template, assigns, "#{db.id}-#{webapp.id}", target_dir)
  end
end
