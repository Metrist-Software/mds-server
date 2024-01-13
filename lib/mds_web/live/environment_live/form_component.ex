defmodule MdsWeb.EnvironmentLive.FormComponent do
  use MdsWeb, :live_component

  alias MdsData.Projects

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage environment records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="environment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input
          field={@form[:options]}
          type="textarea"
          label="Options"
          placeholder="Comma-separated list of k/v pairs"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Environment</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{environment: environment} = assigns, socket) do
    changeset =
      environment
      |> externalize()
      |> Projects.change_environment()

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"environment" => environment_params}, socket) do
    environment_params = internalize(environment_params)

    changeset =
      socket.assigns.environment
      |> Projects.change_environment(environment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"environment" => environment_params}, socket) do
    project = socket.assigns.project

    environment_params =
      environment_params
      |> Map.put("project_id", project.id)
      |> Map.put("creator_id", socket.assigns.user.id)
      |> IO.inspect(label: "Save data")

    save_environment(socket, socket.assigns.action, internalize(environment_params))
  end

  defp save_environment(socket, :edit, environment_params) do
    case Projects.update_environment(socket.assigns.environment, environment_params) do
      {:ok, environment} ->
        notify_parent({:saved, environment})

        {:noreply,
         socket
         |> put_flash(:info, "Environment updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_environment(socket, :new, environment_params) do
    case Projects.create_environment(environment_params) do
      {:ok, environment} ->
        notify_parent({:saved, environment})

        {:noreply,
         socket
         |> put_flash(:info, "Environment created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(externalize(changeset))
    assign(socket, :form, form)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  # TODO cleanup
  defdelegate externalize(v), to: MdsWeb.ResourceLive.FormComponent
  defdelegate internalize(v), to: MdsWeb.ResourceLive.FormComponent
end
