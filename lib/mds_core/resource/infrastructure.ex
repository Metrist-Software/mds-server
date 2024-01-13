defmodule MdsCore.Resource.Infrastructure do
  @moduledoc """
  The infrastructure for a project, probably
  networking, etc.
  """

  use MdsCore.Resource
  require Logger

  @impl true
  def required_options,
    do: [
      :provider
    ]

  @providers %{
    "AWS" => MdsProviders.AWS.Infrastructure
  }

  @impl true
  def gen(resource, deployment, target_dir) do
    lookup_provider(@providers, resource).gen(resource, deployment, target_dir)
  end

  def gen_for(resource = %MdsData.Projects.Resource{type: type}, deployment, target_dir) do
    this = find_this(__MODULE__, deployment.project)
    MdsCore.Resource.type_of(this).gen_for(type, this, resource, deployment, target_dir)
  end

  def gen_for(kind, infra, resource, deployment, target_dir) do
    # Delegate to AWS, etc.
    lookup_provider(@providers, infra).gen_for(kind, infra, resource, deployment, target_dir)
  end

  def deploy(_resource, _deployment, _version, _target_dir, _output_pid), do: :ok
end
