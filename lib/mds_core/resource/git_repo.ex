defmodule MdsCore.Resource.GitRepo do
  @moduledoc """
  A git repository. Has a provider and a location.
  """

  use MdsCore.Resource

  @impl true
  def required_options,
    do: [
      :location,
      :provider
    ]

  @impl true
  def gen(_resource, _deployment, _dir) do
    # TODO check location. If supported, create
    # CI/CD config. Should we create the repo and
    # maybe even populate it? Later. Also,
    # where do we get the keys for the GH repo? We
    # do not want to store them. Probably an interactive,
    # once-only, OAuth2 driven thing to verify existence
    # and set config.
    :ok
  end

  def deploy(_resource, _deployment, _version, _target_dir, _output_pid), do: :ok

  defmodule Providers do
    defmodule GitHub do
    end
  end
end
