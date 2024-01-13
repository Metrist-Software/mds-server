defmodule MdsWeb.ProjectLive.Delete do
  use MdsWeb, :live_view

  alias MdsData.Projects
  import MdsWeb.Live.ProjectAccess, only: [if_accessible_project: 1]

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Delete project
        <:subtitle :if={not @deploy_blocked}>
          Delete project <b class="font-bold"><%= @project.name %></b>? This will also delete all its environments and resources
        </:subtitle>
      </.header>

      <.error :if={@deploy_blocked}>
        There is currently an on going deployment. Please try again later
      </.error>

      <div :if={not @deploy_blocked}>
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

        <div :if={@progress == :in_progress}>
          <.progress_text
            environments={@environments}
            env_progress={@env_progress}
            in_progress_env={@in_progress_env}
          />
        </div>

        <div :if={@progress == :success} class="my-6">
          <p><%= @result %></p>

          <.back navigate={~p"/"}>Back to projects</.back>
        </div>

        <div :if={@progress == :failed} class="my-6"></div>

        <MdsWeb.CommonComponents.logs id="messages" messages={@messages} />
      </div>
    </div>
    """
  end

  defp progress_text(assigns) do
    in_progress_env =
      Enum.find(assigns.environments, fn %{id: env_id} -> assigns.in_progress_env == env_id end)

    assigns = assign(assigns, in_progress_env: in_progress_env)

    ~H"""
    <div class="my-6">
      <span :if={@in_progress_env}>
        Destroying environment <b class="font-bold"><%= @in_progress_env.name %></b>. <%= map_size(
          @env_progress
        ) %>/<%= length(@environments) %>
      </span>
    </div>
    """
  end

  defp assign_deploy_blocked(socket) do
    assigns = socket.assigns
    project = assigns.project

    deploy_blocked =
      match?(
        %{state: state} when state in [:in_progress],
        MdsData.Deployments.last_deployment(project)
      )

    assign(socket, deploy_blocked: deploy_blocked)
  end

  @impl true
  def mount(params, _session, socket) do
    socket =
      if_accessible_project do
        environments = MdsData.Projects.list_environments(project)

        socket
        |> assign(project: project)
        |> assign(environments: environments)
        |> assign(challenge: "permanently delete")
        |> assign(next_msg_id: 0)
        |> assign(messages: [])
        |> assign(progress: nil)
        |> assign(in_progress_env: nil)
        |> assign(env_progress: %{})
        |> assign(:form, to_form(%{}))
        |> assign_deploy_blocked()
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", params, socket) do
    {:noreply, assign(socket, :form, to_form(params))}
  end

  def handle_event("save", _params, socket) do
    project = socket.assigns.project
    environments = socket.assigns.environments

    me = self()

    Task.Supervisor.start_child(MdsServer.TaskSupervisor, fn ->
      try do
        for environment <- environments do
          send(me, {:env_progress, environment.id, :in_progress})

          {:ok, deployment} =
            MdsData.Deployments.create_deployment(
              project,
              environment,
              :app,
              :web,
              socket.assigns.user.id
            )

          MdsCore.Deployment.down(deployment, me)
          # TODO: This hack avoids deployments from being deleted before logs are being written
          Process.sleep(:timer.seconds(5))
          MdsData.Deployments.delete_all_deployment_by_environment_id(environment.id)
          Projects.delete_environment(environment)
          send(me, {:env_progress, environment.id, :completed})
        end

        Projects.delete_all_resources_by_project_id(project.id)
        Projects.delete_project(project)
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

  def handle_info({:env_progress, id, state}, socket) do
    in_progress_env =
      if state == :in_progress do
        id
      end

    {:noreply,
     socket
     |> update(:env_progress, fn env_progress ->
       Map.put(env_progress, id, state)
     end)
     |> assign(in_progress_env: in_progress_env)}
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
      |> assign(result: "Successfully deleted project")

    {:noreply, socket}
  end
end
