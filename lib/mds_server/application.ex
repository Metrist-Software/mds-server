defmodule MdsServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting build: #{build_txt()}")
    configure()

    children = [
      # Start the Telemetry supervisor
      MdsWeb.Telemetry,
      # Start the Ecto repository
      MdsData.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: MdsServer.PubSub},
      # Start Finch
      {Finch, name: MdsServer.Finch},
      # Start the Endpoint (http/https)
      MdsWeb.Endpoint,
      # Start a worker by calling: MdsData.Worker.start_link(arg)
      # {MdsData.Worker, arg}
      {Task.Supervisor, name: MdsServer.TaskSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MdsServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MdsWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp configure() do
    # Configure some stuff that is really runtime but we also want to treat as runtime in dev.
    configure_oauth_github()
    configure_oauth_google()
  end

  defp configure_oauth_github() do
    # TODO this now appears twice, here and runtime.exs
    github_secret = MdsData.Secrets.get_secret("oauth/github")

    Application.put_env(:ueberauth, Ueberauth.Strategy.Github.OAuth,
      client_id: Map.get(github_secret, "client_id"),
      client_secret: Map.get(github_secret, "client_secret")
    )
  end

  defp configure_oauth_google() do
    google_secret = MdsData.Secrets.get_secret("oauth/google")

    Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth,
      client_id: Map.get(google_secret, "client_id"),
      client_secret: Map.get(google_secret, "client_secret")
    )
  end


  def build_txt() do
    build_txt = Path.join([Application.app_dir(:mds_server), "priv", "static", "build.txt"])
    if File.exists?(build_txt) do
      File.read!(build_txt)
    else
      "(no build file, localdev?)"
    end
  end

  def tmp_dir() do
    Application.get_env(:mds_server, :temp_dir)
    |> Kernel.||(System.tmp_dir())
  end
end
