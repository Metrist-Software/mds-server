defmodule MdsCore.Resource.Database do
  @moduledoc """
  A database. Has a provider, currently must be PostgreSQL.
  """

  use MdsCore.Resource

  @impl true
  def required_resources,
    do: [
      MdsCore.Resource.Infrastructure
    ]

  @impl true
  def required_options,
    do: [
      :provider
    ]

  @providers %{
    "AWS" => MdsProviders.AWS.Database
  }

  @impl true
  def gen(resource, deployment, target_dir) do
    MdsCore.Resource.Infrastructure.gen_for(resource, deployment, target_dir)
    lookup_provider(@providers, resource).gen(resource, deployment, target_dir)
    # TODO create database. If it exists,
    # migrate it.
    :ok
  end

  def gen_for(resource = %MdsData.Projects.Resource{type: type}, deployment, target_dir) do
    this = find_this(__MODULE__, deployment.project)
    # TODO same in infra, I think we can just write __MODULE__ here
    MdsCore.Resource.type_of(this).gen_for(type, this, resource, deployment, target_dir)
  end

  def gen_for(kind, db, resource, deployment, target_dir) do
    # Delegate to AWS, etc.
    lookup_provider(@providers, db).gen_for(kind, db, resource, deployment, target_dir)
  end

  def deploy(_resource, _deployment, _version, _target_dir, _output_pid), do: :ok
end
