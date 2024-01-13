defmodule MdsWeb.Live.Home do
  use MdsWeb, :live_view

  @impl true
  def mount(_param, session, socket) do
    projects = MdsData.Projects.get_projects_by_account(session["account"], [:environments])

    socket = if Enum.empty?(projects) && socket.assigns.live_action != :new do
      redirect(socket, to: ~p"/new")
    else
      socket
    end

    socket =
      socket
      |> assign(projects: projects)
      |> assign(user_id: session["user"].id)
      |> assign(account_id: session["account"].id)
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:project_setup_complete, project_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/projects/#{project_id}/doc")}
  end
end
