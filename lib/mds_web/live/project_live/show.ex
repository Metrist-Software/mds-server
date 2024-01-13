defmodule MdsWeb.ProjectLive.Show do
  use MdsWeb, :live_view

  import MdsWeb.Live.ProjectAccess, only: [if_accessible_project: 1]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    socket =
      if_accessible_project do
        socket
        |> assign(:page_title, page_title(socket.assigns.live_action))
        |> assign(:project, project)
      end
    {:noreply, socket}
  end

  defp page_title(:show), do: "Show Project"
  defp page_title(:edit), do: "Edit Project"
end
