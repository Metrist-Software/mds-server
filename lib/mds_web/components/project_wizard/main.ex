defmodule MdsWeb.Components.ProjectWizard.Step do
  defstruct [:name, :prev, :next, :component]
end

defmodule MdsWeb.Components.ProjectWizard.Main do
  use MdsWeb, :live_component

  alias MdsWeb.Components.ProjectWizard.{Step}

  @steps [
    %Step{name: "Stack",    prev: nil,        next: "Provider", component: MdsWeb.Components.ProjectWizard.Stack},
    %Step{name: "Provider", prev: "Stack",    next: "Config",   component: MdsWeb.Components.ProjectWizard.Provider},
    %Step{name: "Config",   prev: "Provider", next: "Create",   component: MdsWeb.Components.ProjectWizard.Config},
    %Step{name: "Create",   prev: nil,        next: nil,        component: MdsWeb.Components.ProjectWizard.Create},
  ]

  @impl true
  def mount(socket) do
    [step | _] = @steps

    socket = assign(socket,
      steps: @steps,
      progress: step,
      state: %{stack: nil, provider: nil, config: %{}})

    {:ok, socket}
  end

  @impl true
  def update(%{goto: :next, stack: stack}, socket) do
    {:ok, assign(socket,
      state: Map.put(socket.assigns.state, :stack, stack),
      progress: next_step(socket.assigns.progress))}
  end

  def update(%{goto: :next, provider: provider}, socket) do
    {:ok, assign(socket,
      state: Map.put(socket.assigns.state, :provider, provider),
      progress: next_step(socket.assigns.progress))}
  end

  def update(%{goto: :next, config: config}, socket) do
    socket = socket
    |> assign(config: config)
    |> assign(progress: next_step(socket.assigns.progress))

    # Going to push to the "Creating Project" page. Spawn a task here to do the actual work
    setup_project(socket.assigns)

    {:ok, socket}
  end

  def update(%{goto: :next}, socket) do
    {:ok, assign(socket, progress: next_step(socket.assigns.progress))}
  end

  def update(%{goto: :previous}, socket) do
    {:ok, assign(socket, progress: previous_step(socket.assigns.progress))}
  end

  def update(assigns, socket) do
    {:ok, assign(socket,
      id: assigns.id,
      user_id: assigns.user_id,
      account_id: assigns.account_id)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="setup-wizard">
      <h1 class="text-center">
        New Project
      </h1>

      <div class="flex flex-row gap-x-3">
        <div
          :for={step <- @steps}
          class={"w-3 h-3 rounded-full #{if @progress.name == step.name, do: "bg-blue-400", else: "bg-gray-500"}"}
        />
      </div>

      <.live_component module={@progress.component} id="current-form" parent_id={@id} state={@state}/>
    </div>
    """
  end

  defp next_step(%Step{next: nil}), do: nil
  defp next_step(%Step{next: next}), do: Enum.find(@steps, & &1.name == next)

  defp previous_step(%Step{prev: nil}), do: nil
  defp previous_step(%Step{prev: previous}), do: Enum.find(@steps, & &1.name == previous)

  defp setup_project(assigns) do
    pid = self()

    Task.start_link(fn ->
      {:ok, project} = MdsData.Projects.create_project(%{
        name: assigns.config["name"],
        account_id: assigns.account_id,
        creator_id: assigns.user_id,
      })

      {:ok, _resource} = MdsData.Projects.create_resource(%{
        options: %{provider: assigns.state.provider},
        type: "Infrastructure",
        project_id: project.id,
        creator_id: assigns.user_id
      })

      {:ok, _resource} = MdsData.Projects.create_resource(%{
        options: %{provider: assigns.state.provider, db: "PostgreSQL", instance_size: "serverless"},
        type: "Database",
        project_id: project.id,
        creator_id: assigns.user_id
      })

      {:ok, _resource} = MdsData.Projects.create_resource(%{
        options: %{language: assigns.state.stack, provider: assigns.state.provider},
        type: "WebApp",
        project_id: project.id,
        creator_id: assigns.user_id
      })

      {:ok, environment} = MdsData.Projects.create_environment(%{
        name: assigns.config["environment"],
        options: %{aws_region: assigns.config["region"]},
        project_id: project.id,
        creator_id: assigns.user_id
      })

      MdsData.Secrets.create_secret(
        "environments/#{environment.id}",
        %{
          aws_access_key_id: assigns.config["aws_access_key_id"],
          aws_secret_access_key: assigns.config["aws_secret_access_key"]
        }
      )

      Process.sleep(1000)
      send(pid, {:project_setup_complete, project.id})
    end)
  end
end
