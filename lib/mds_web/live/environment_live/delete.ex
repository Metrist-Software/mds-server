defmodule MdsWeb.EnvironmentLive.Delete do
  use MdsWeb, :live_view

  alias MdsData.Projects
  import MdsWeb.Live.ProjectAccess, only: [if_accessible_project: 1]

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Delete environment
        <:subtitle>
          Delete environment "<%= @environment.name %>"? This will also deprovision all resources in this environment
        </:subtitle>
      </.header>

      <.simple_form
        :if={@progress == nil}
        for={@form}
        id="confirmation-form"
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:answer]}
          type="text"
          label={"To confirm deletion, enter \"#{@challenge}\""}
        />
        <:actions>
          <.button
            disabled={Phoenix.HTML.Form.input_value(@form, :answer) != @challenge}
            phx-disable-with="Deleting..."
          >
            Delete
          </.button>
        </:actions>
      </.simple_form>

      <div if={@progress == :in_progress} class="my-6">
        Deletion in progress. Please keep this tab open
      </div>

      <div :if={@progress == :success} class="my-6">
        <p><%= @result %></p>

        <.back navigate={~p"/environments/#{@environment.project_id}"}>Back to environments</.back>
      </div>

      <MdsWeb.CommonComponents.logs id="messages" messages={@messages}/>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    socket =
      if_accessible_project do
        environment = Projects.get_environment!(params["id"])

        socket
        |> assign(project: project)
        |> assign(environment: environment)
        |> assign(challenge: "permanently delete")
        |> assign(next_msg_id: 0)
        |> assign(messages: [])
        |> assign(progress: nil)
        |> assign(:form, to_form(%{}))
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", params, socket) do
    {:noreply, assign(socket, :form, to_form(params))}
  end

  def handle_event("save", _params, socket) do
    {:ok, deployment} =
      MdsData.Deployments.create_deployment(
        socket.assigns.project,
        socket.assigns.environment,
        :app,
        :web,
        socket.assigns.user.id
      )

    me = self()

    Task.Supervisor.start_child(MdsServer.TaskSupervisor, fn ->
      try do
        MdsCore.Deployment.down(deployment, me)
        environment = socket.assigns.environment
        MdsData.Deployments.delete_all_deployment_by_environment_id(environment.id)
        Projects.delete_environment(environment)
        send(me, :exit_successful)
      rescue
        err ->
          Logger.error(Exception.format(:error, err, __STACKTRACE__))
          send(me, :exit_unsuccessful)
      end
    end)

    {:noreply, assign(socket, progress: :in_progress)}
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
      |> assign(progress: :failed)
      |> assign(
        result:
          "The deletion was unsuccessful. Please review the error messages below and retry after correcting what caused them."
      )

    {:noreply, socket}
  end

  def handle_info(:exit_successful, socket) do
    socket =
      socket
      |> assign(progress: :success)
      |> assign(result: "Successfully deleted environment")

    {:noreply, socket}
  end
end
