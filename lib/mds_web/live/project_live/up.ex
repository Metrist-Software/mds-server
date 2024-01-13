defmodule MdsWeb.ProjectLive.Up do
  use MdsWeb, :live_view

  require Logger
  import MdsWeb.Live.ProjectAccess, only: [if_accessible_project: 1]

  @impl true
  def mount(params, _session, socket) do
    socket =
      if_accessible_project do
        environment = MdsData.Projects.get_environment!(params["environment_id"])

        socket
        |> assign(has_confirmed: false)
        |> assign(project: project)
        |> assign(environment: environment)
        |> assign(next_msg_id: 1)
        |> assign(messages: [%{id: 0, text: "Deployment starting up..."}])
        |> assign(result: "")
        |> assign_deploy_blocked()
      end

    {:ok, socket, temporary_assigns: [messages: []]}
  end

  @impl true
  def handle_event("confirm", _, socket) do
    socket =
      socket
      |> assign_deploy_blocked()
      |> do_confirm()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:info, message}, socket) do
    socket =
      socket
      |> assign(messages: [%{id: socket.assigns.next_msg_id, text: message}])
      |> assign(next_msg_id: socket.assigns.next_msg_id + 1)

    {:noreply, socket}
  end

  def handle_info({:error, message, error}, socket) do
    socket =
      socket
      |> assign(
        messages: [
          %{id: socket.assigns.next_msg_id, text: message, is_error: true},
          %{id: socket.assigns.next_msg_id + 1, text: inspect(error), is_error: true}
        ]
      )
      |> assign(next_msg_id: socket.assigns.next_msg_id + 2)

    {:noreply, socket}
  end

  def handle_info(:exit_unsuccessful, socket) do
    socket =
      socket
      |> assign(
        result:
          "The infrastructure creation/update was unsuccessful. Please review the error messages above and retry after correcting what caused them."
      )

    {:noreply, socket}
  end

  def handle_info(:exit_successful, socket) do
    socket =
      socket
      |> assign(
        result:
          "The infrastructure creation/update was successful. You can now deploy code to it."
      )

    {:noreply, socket}
  end

  def handle_info(event, socket) do
    IO.inspect(event, label: "Received event")
    {:noreply, socket}
  end

  @impl true
  def render(assigns = %{has_confirmed: false}) do
    ~H"""
    <.header>
      Bring Infrastructure up for <%= @project.name %>/<%= @environment.name %>
      <:subtitle>
        <p>
          This action will create or update infrastructure for the "<%= @environment.name %>"
          environment in the "<%= @project.name %>" project. Creating infrastructures will incur
          charges with your hosting/cloud provider. Only continue if you are sure that you are
          fine with this.
        </p>
      </:subtitle>
      <:actions>
        <.button
          :if={not @deploy_blocked}
          phx-click="confirm"
          class="rounded-md bg-emerald-800 p-2 text-white"
        >
          Confirm
        </.button>
      </:actions>
    </.header>
    <.error :if={@deploy_blocked}>There is currently an on going deployment. Please try again later</.error>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <h1>Bringing up infrastructure for <%= @project.name %>/<%= @environment.name %></h1>
    </.header>

    <MdsWeb.CommonComponents.logs id="messages" messages={@messages} />

    <div id="result" class="mt-8">
      <%= @result %>
    </div>
    """
  end

  defp do_confirm(socket) when not socket.assigns.deploy_blocked do
    {:ok, deployment} =
      MdsData.Deployments.create_deployment(
        socket.assigns.project,
        socket.assigns.environment,
        :infra,
        :web,
        socket.assigns.user.id
      )

    socket =
      socket
      |> assign(has_confirmed: true)
      |> assign(deployment: deployment)

    me = self()

    Task.Supervisor.start_child(MdsServer.TaskSupervisor, fn ->
      try do
        case MdsCore.Deployment.up(deployment, me) do
          :ok -> send(me, :exit_successful)
          :error -> send(me, :exit_unsuccessful)
        end
      rescue
        err ->
          Logger.error(Exception.format(:error, err, __STACKTRACE__))
          send(me, :exit_unsuccessful)
      end
    end)

    socket
  end

  defp do_confirm(socket) do
    socket
    |> put_flash(:error, "Cannot deploy at the moment")
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
