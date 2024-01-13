defmodule MdsWeb.ProjectLive.Doc do
  use MdsWeb, :live_view
  import MdsWeb.Live.ProjectAccess, only: [if_accessible_project: 1]

  require Logger

  @impl true
  def mount(params, session, socket) do
    socket =
      if_accessible_project do
        api_key = MdsData.Accounts.get_api_key(session["user"]).key
        environments = MdsData.Projects.list_environments(project)

        states_by_env =
          environments
          |> Enum.map(fn e ->
            {e.id, MdsData.Deployments.last_deployment_state(project, e)}
          end)
          |> Map.new()

        socket
        |> assign(project: project)
        |> assign(environments: environments)
        |> assign(api_key: api_key)
        |> assign(states_by_env: states_by_env)
        |> assign(shown_api_token: "(click to reveal)")
        |> assign(reveal_hide: "reveal")
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle-api-token", _, socket) do
    socket =
      if socket.assigns.reveal_hide == "reveal" do
        socket
        |> assign(shown_api_token: socket.assigns.api_key)
        |> assign(reveal_hide: "hide")
      else
        socket
        |> assign(shown_api_token: "(click to reveal)")
        |> assign(reveal_hide: "reveal")
      end

    {:noreply, socket}
  end

  def container_repository(states_by_env, e) do
    states_by_env[e.id]["outputs"]["mds_webapp_container_repository"]["value"]
    |> IO.inspect(label: "repo for #{e.id}")
  end
end
