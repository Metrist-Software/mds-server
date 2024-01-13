defmodule MdsWeb.ProjectLive.History do
  use MdsWeb, :live_view

  import MdsWeb.Live.ProjectAccess, only: [if_accessible_project: 1]

  @impl true
  def mount(params, _session, socket) do
    socket =
      if_accessible_project do
        environment = MdsData.Projects.get_environment!(params["environment_id"])
        deployments = MdsData.Deployments.list_deployments(project, environment)

        socket
        |> assign(project: project)
        |> assign(environment: environment)
        |> assign(deployments: deployments)
      end

    {:ok, socket}
  end

  # Helpers

  def has_log?(deployment) do
    log = deployment.log
    not is_nil(log) and log != []
  end
end
