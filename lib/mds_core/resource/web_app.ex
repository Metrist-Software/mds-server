defmodule MdsCore.Resource.WebApp do
  @moduledoc """
  A webapp. Lives in a git repo and is backed by a
  database.
  """

  use MdsCore.Resource

  @impl true
  def required_resources,
    do: [
      MdsCore.Resource.Infrastructure,
      MdsCore.Resource.GitRepo,
      MdsCore.Resource.Database
    ]

  @impl true
  def required_options,
    do: [
      :language,
      # ? maybe drop this?
      :provider
    ]

  @providers %{
    "AWS" => MdsProviders.AWS.WebApp
  }

  @impl true
  def gen(resource, deployment, target_dir) do
    MdsCore.Resource.Infrastructure.gen_for(resource, deployment, target_dir)
    MdsCore.Resource.Database.gen_for(resource, deployment, target_dir)

    lookup_provider(@providers, resource).gen(resource, deployment, target_dir)
    :ok
  end

  def deploy(resource, deployment, version, target_dir, logging_pid) do
    lookup_provider(@providers, resource).deploy(resource, deployment, version, target_dir, logging_pid)
  end
end
