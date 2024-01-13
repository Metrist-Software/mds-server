defmodule MdsWeb.EnvironmentLive.Index do
  use MdsWeb, :live_view

  alias MdsData.Projects
  alias MdsData.Projects.Environment
  import MdsWeb.Live.ProjectAccess, only: [if_accessible_project: 1]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      if_accessible_project do
        socket
        |> assign(:project, project)
        |> detach_hook(:environments, :after_render)
        |> stream(:environments, Projects.list_environments(project))
        |> apply_action(socket.assigns.live_action, params)
      end
    {:noreply, socket}
  end

  defp apply_action(socket, :edit, %{"environment_id" => id}) do
    socket
    |> assign(:page_title, "Edit Environment")
    |> assign(:environment, Projects.get_environment!(id))
  end

  defp apply_action(socket, :delete, %{"environment_id" => id}) do
    socket
    |> assign(:page_title, "Delete Environment")
    |> assign(:environment, Projects.get_environment!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Environment")
    |> assign(:environment, %Environment{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Environments")
    |> assign(:environment, nil)
  end

  @impl true
  def handle_info({MdsWeb.EnvironmentLive.FormComponent, {:saved, environment}}, socket) do
    {:noreply, stream_insert(socket, :environments, environment)}
  end
end
