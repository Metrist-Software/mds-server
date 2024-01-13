defmodule MdsWeb.ProjectLive.Deploy do
  use MdsWeb, :live_view

  require Logger
  import MdsWeb.Live.ProjectAccess, only: [if_accessible_project: 1]

  @impl true
  def mount(params, _session, socket) do
    socket =
      if_accessible_project do
        environment = MdsData.Projects.get_environment!(params["environment_id"])

        socket
        |> assign(project: project)
        |> assign(environment: environment)
        |> assign(tag: nil)
        |> assign(next_msg_id: 1)
        |> assign(messages: [%{id: 0, text: "Deployment starting up..."}])
        |> assign(result: "")
        |> assign_deploy_blocked()
      end

    {:ok, socket, temporary_assigns: [messages: []]}
  end

  @impl true
  def handle_event("go", %{"tag" => tag}, socket) do
    socket =
      if String.length(tag) == 0 do
        socket
      else
        {:ok, deployment} =
          MdsData.Deployments.create_deployment(
            socket.assigns.project,
            socket.assigns.environment,
            :app,
            :web,
            socket.assigns.user.id,
            tag
          )

        socket =
          socket
          |> assign(has_confirmed: true)
          |> assign(deployment: deployment)
          |> assign(tag: tag)

        me = self()

        Task.Supervisor.start_child(MdsServer.TaskSupervisor, fn ->
          try do
            MdsCore.Deployment.deploy(deployment, tag, me)
            send(me, :exit_successful)
          rescue
            err ->
              Logger.error(Exception.format(:error, err, __STACKTRACE__))
              send(me, :exit_unsuccessful)
          end
        end)

        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:info, message}, socket) do
    socket =
      socket
      |> assign(messages: [%{id: socket.assigns.next_msg_id, text: "  " <> message}])
      |> assign(next_msg_id: socket.assigns.next_msg_id + 1)

    {:noreply, socket}
  end

  def handle_info({:error, message, error}, socket) do
    socket =
      socket
      |> assign(messages: [%{id: socket.assigns.next_msg_id, text: message, is_error: true},
                           %{id: socket.assigns.next_msg_id + 1, text: inspect(error), is_error: true}])
      |> assign(next_msg_id: socket.assigns.next_msg_id + 2)

    {:noreply, socket}
  end

  def handle_info(:exit_unsuccessful, socket) do
    socket =
      socket
      |> assign(result: "The deploy was unsuccessful. Please review the error messages above and retry after correcting what caused them.")
    {:noreply, socket}
  end

  def handle_info(:exit_successful, socket) do
    socket =
      socket
      |> assign(result: "The deploy looks successful. Please review the output above before accessing the application.")
    {:noreply, socket}
  end

  @impl true
  def render(assigns = %{tag: nil}) do
    ~H"""
    <.header>
      Deploy <%= @project.name %>/<%= @environment.name %>
      <:subtitle :if={not @deploy_blocked}>
        In order to deploy software, we need to know what version to deploy. Please specify
        the tag of the container (normally the Git short revision) that you want to be
        deployed to the "<%= @environment.name %>"
        environment in the "<%= @project.name %>" project.
      </:subtitle>
    </.header>
    <div :if={not @deploy_blocked}>
      <div class="mt-2 text-sm leading-6 text-zinc-600">Fill in the tag and hit [Enter] to start the deployment.</div>
      <form phx-submit="go" >
        <input id="tag" name="tag" type="text" value="" />
      </form>
    </div>
    <.error :if={@deploy_blocked}>There is currently an on going deployment. Please try again later</.error>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Deploying version <%= @tag %> to <%= @project.name %>/<%= @environment.name %></h1>
    <MdsWeb.CommonComponents.logs id="messages" messages={@messages}/>
    <div id="result" class="mt-8">
      <%= @result %>
    </div>
    """
  end

  defp assign_deploy_blocked(socket) do
    assigns = socket.assigns
    project = assigns.project
    environment = assigns.environment

    deploy_blocked =
      match?(
        %{state: state} when state in [:in_progress],
        MdsData.Deployments.last_deployment(project, environment)
      )

    assign(socket, deploy_blocked: deploy_blocked)
  end
end
