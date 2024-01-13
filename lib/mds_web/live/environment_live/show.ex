defmodule MdsWeb.EnvironmentLive.Show do
  use MdsWeb, :live_view

  alias MdsData.Projects
  import MdsWeb.Live.ProjectAccess, only: [if_accessible_project: 1]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    socket =
      if_accessible_project do
        environment = Projects.get_environment!(params["environment_id"])

        if environment.project_id != project.id do
          socket
          |> put_flash(:error, "Environment does not belong to project")
          |> redirect(to: "/")
        else
          socket
          |> assign(:page_title, page_title(socket.assigns.live_action))
          |> assign(project: project)
          |> assign(:environment, Projects.get_environment!(params["environment_id"]))
        end
      end

    {:noreply, socket}
  end

  defp page_title(:show), do: "Show Environment"
  defp page_title(:edit), do: "Edit Environment"
end
