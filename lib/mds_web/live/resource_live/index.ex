defmodule MdsWeb.ResourceLive.Index do
  use MdsWeb, :live_view

  alias MdsData.Projects
  alias MdsData.Projects.Resource
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
          |> detach_hook(:resources, :after_render)
          |> stream(:resources, Projects.list_resources(project))
          |> apply_action(socket.assigns.live_action, params)
      end

    {:noreply, socket}
  end

  defp apply_action(socket, :edit, %{"resource_id" => id}) do
    socket
    |> assign(:page_title, "Edit Resource")
    |> assign(:resource, Projects.get_resource!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Resource")
    |> assign(:resource, %Resource{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Resources")
    |> assign(:resource, nil)
  end

  @impl true
  def handle_info({MdsWeb.ResourceLive.FormComponent, {:saved, resource}}, socket) do
    {:noreply, stream_insert(socket, :resources, resource)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    resource = Projects.get_resource!(id)
    {:ok, _} = Projects.delete_resource(resource)

    {:noreply, stream_delete(socket, :resources, resource)}
  end

  defdelegate externalize_options(options), to: Resource
end
