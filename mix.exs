defmodule MdsData.MixProject do
  use Mix.Project

  def project do
    [
      app: :mds_server,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {MdsServer.Application, []},
      extra_applications: [:logger, :runtime_tools, :ssh]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:base62, "~> 1.2"},
      {:bbmustache, "~> 1.12"},
      {:configparser_ex, "~> 4.0"},
      {:ecto_sql, "~> 3.6"},
      {:elixir_xml_to_map, "~> 3.0"},
      {:ex_aws, "~> 2.4"},
      {:ex_aws_ec2, "~> 2.0"},
      {:ex_aws_rds, "~> 2.0"},
      {:ex_aws_secretsmanager, "~> 2.0"},
      {:finch, "~> 0.13"},
      {:floki, ">= 0.30.0", only: :test},
      {:jason, "~> 1.2"},
      {:hackney, "~> 1.18"},
      {:heroicons, "~> 0.5.2"},
      {:libgraph, "~> 0.16.0"},
      {:phoenix, "~> 1.7.2"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_dashboard, "~> 0.7.2"},
      {:phoenix_live_view, "~> 0.18.16"},
      {:plug_cowboy, "~> 2.5"},
      {:postgrex, ">= 0.0.0"},
      {:swoosh, "~> 1.3"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:ueberauth, "~> 0.10.5"},
      {:ueberauth_github, "~> 0.8.2"},
      {:ueberauth_google, "~> 0.10"},
      {:dialyxir, "~> 1.3", only: :dev, runtime: false},
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: [
        "deps.get",
        "ecto.setup",
        "assets.setup",
        "assets.build"
      ],
      "ecto.setup": [
        "ecto.create",
        "ecto.migrate",
        "run priv/repo/seeds.exs"
      ],
      "ecto.reset": [
        "ecto.drop",
        "ecto.setup"
      ],
      test: [
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "test"
      ],
      "assets.setup": [
        "tailwind.install --if-missing",
        "esbuild.install --if-missing"
      ],
      "assets.build": [
        "tailwind default",
        "esbuild default"
      ],
      "assets.deploy": [
        # Ideally we should this before a deploy but as it stands, we don't have NPM/npx in the
        # build container
        # fn _ -> Mix.shell().cmd("npx --prefix assets update-browserslist-db@latest") end,
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end
end
