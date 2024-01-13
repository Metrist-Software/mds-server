defmodule MdsWeb.ResourceLive.Show do
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
        resource = Projects.get_resource!(params["resource_id"])

        if resource.project_id != project.id do
          socket
          |> put_flash(:error, "Resource does not belong to project")
          |> redirect(to: "/")
        else
          socket
          |> assign(:page_title, page_title(socket.assigns.live_action))
          |> assign(:resource, resource)
          |> assign(:project, project)
        end
      end

    {:noreply, socket}
  end

  defp page_title(:show), do: "Show Resource"
  defp page_title(:edit), do: "Edit Resource"
end
