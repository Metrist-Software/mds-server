defmodule MdsWeb.ResourceLive.FormComponent do
  use MdsWeb, :live_component

  alias MdsData.Projects
  alias MdsData.Projects.Resource

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage resource records for
          the <%= @project.name %> project.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="resource-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:type]}
          type="select"
          label="Type"
          options={[
            "Git Repository": "GitRepository",
            "Web/API Application": "WebApp",
            Database: "Database",
            Infrastructure: "Infrastructure"
          ]}
        />
        <.input
          field={@form[:options]}
          type="textarea"
          label="Options"
          placeholder="Comma-separated list of k/v pairs"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Resource</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{resource: resource} = assigns, socket) do
    changeset =
      resource
      |> externalize()
      |> Projects.change_resource()

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"resource" => resource_params}, socket) do
    resource_params = internalize(resource_params)

    changeset =
      socket.assigns.resource
      |> Projects.change_resource(resource_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"resource" => resource_params}, socket) do
    project = socket.assigns.project

    resource_params =
      resource_params
      |> Map.put("project_id", project.id)
      |> Map.put("creator_id", socket.assigns.user.id)
      |> IO.inspect(label: "Save data")

    save_resource(socket, socket.assigns.action, internalize(resource_params))
  end

  defp save_resource(socket, :edit, resource_params) do
    case Projects.update_resource(socket.assigns.resource, resource_params) do
      {:ok, resource} ->
        notify_parent({:saved, resource})

        {:noreply,
         socket
         |> put_flash(:info, "Resource updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_resource(socket, :new, resource_params) do
    case Projects.create_resource(resource_params) do
      {:ok, resource} ->
        notify_parent({:saved, resource})

        {:noreply,
         socket
         |> put_flash(:info, "Resource created successfully")
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

  def externalize(%Ecto.Changeset{} = changeset) do
    if changeset.changes == %{} do
      changeset
    else
      if Ecto.Changeset.changed?(changeset, :options) do
        Ecto.Changeset.change(changeset, %{
          options: Resource.externalize_options(changeset.changes.options)
        })
      else
        changeset
      end
    end
  end

  def externalize(%{} = resource) do
    if is_nil(resource.options) do
      resource
    else
      Map.update!(resource, :options, &Resource.externalize_options/1)
    end
  end

  def internalize(resource_params) do
    options =
      resource_params
      |> Map.get("options")
      |> Resource.internalize_options()

    resource_params
    |> Map.put("options", options)
  end
end
