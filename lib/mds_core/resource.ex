defmodule MdsCore.Resource do
  @moduledoc """
  Common interface and support code for resources.

  Use through `use MdsCore.Resource` when implementing
  resources.
  """

  @type_map %{
    "GitRepository" => MdsCore.Resource.GitRepo,
    "WebApp" => MdsCore.Resource.WebApp,
    "Database" => MdsCore.Resource.Database,
    "Infrastructure" => MdsCore.Resource.Infrastructure
  }

  @doc """
  Return a list of required options for the resource.
  """
  @callback required_options() :: [atom()]

  @doc """
  Return a list of required resources for the resource.
  """
  @callback required_resources() :: [atom()]

  @doc """
  Generate Terraform code
  """
  @callback gen(
              resource :: %MdsData.Projects.Resource{},
              deployment :: %MdsData.Deployments.Deployment{},
              target_dir :: String.t()
            ) :: :ok | :error

  def type_of(resource_type_string) when is_binary(resource_type_string) do
    Map.get(@type_map, resource_type_string) || raise "No type defined for #{resource_type_string}"
  end

  def type_of(resource = %MdsData.Projects.Resource{}) do
    type_of(resource.type)
  end

  def type_of(other) do
    raise "Cannot determine type of #{inspect other}"
  end

  @doc """
  Given a map of providers, look up the provider for the resource. This
  assumes that the resource has the standard "provider" options.
  """
  def lookup_provider(providers, resource) do
    resource
    |> MdsData.Projects.Resource.provider()
    |> then(&Map.get(providers, &1))
  end

  @doc """
  Given a project, find the resource that pertains to the
  module of the caller.
  """
  def find_this(module, project) do
    Enum.find(project.resources, fn candidate ->
      module == Map.get(@type_map, candidate.type)
    end)
  end

  defmacro __using__(_opts) do
    quote do
      @behaviour MdsCore.Resource
      import MdsCore.Resource

      def required_options, do: []
      defoverridable required_options: 0

      def required_resources, do: []
      defoverridable required_resources: 0
    end
  end
end
