defmodule MdsWeb.ProjectLive.Index do
  use MdsWeb, :live_view

  alias MdsData.Projects
  alias MdsData.Projects.Project
  import MdsWeb.Live.ProjectAccess, only: [if_accessible_project: 1]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :projects, Projects.get_projects_by_account(socket.assigns.account))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, params) do
    if_accessible_project do
      socket
      |> assign(:page_title, "Edit Project")
      |> assign(:project, project)
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Project")
    |> assign(:project, %Project{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Projects")
    |> assign(:project, nil)
  end

  @impl true
  def handle_info({MdsWeb.ProjectLive.FormComponent, {:saved, project}}, socket) do
    {:noreply, stream_insert(socket, :projects, project)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    project = Projects.get_project!(id)
    {:ok, _} = Projects.delete_project(project)

    {:noreply, stream_delete(socket, :projects, project)}
  end
end
