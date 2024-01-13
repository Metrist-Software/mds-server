defmodule MdsWeb.Components.ProjectWizard.Config do
  use MdsWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket,
      parent_id: assigns.parent_id,
      stack: assigns.state.stack,
      provider: assigns.state.provider,
      form: get_form(assigns.state.provider, assigns.state.stack, assigns.state.config)
    )}
  end

  @impl true
  def handle_event("submit", data, socket) do
    send_update(MdsWeb.Components.ProjectWizard.Main, id: socket.assigns.parent_id, config: data, goto: :next)

    {:noreply, socket}
  end

  def handle_event("previous", _, socket) do
    send_update(MdsWeb.Components.ProjectWizard.Main, id: socket.assigns.parent_id, goto: :previous)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2>Configure Your Project</h2>

      <.simple_form
        for={@form}
        id="deployment-form"
        phx-target={@myself}
        phx-submit="submit"
      >
        <.input field={@form[:name]} type="text" label="Name" required />
        <.input field={@form[:environment]} type="text" label="Environment Name" required />
        <.input field={@form[:region]} type="select" label="Region" options={provider_regions(@provider)} required />

        <.provider_inputs form={@form} provider={@provider} />

        <:actions>
          <.button type="button" phx-click="previous" phx-target={@myself}>Previous</.button>
          <.button>Submit</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def provider_inputs(assigns=%{provider: "AWS"}) do
    ~H"""
      <.input field={@form[:aws_access_key_id]} type="text" label="Access Key ID" required />
      <.input field={@form[:aws_secret_access_key]} type="text" label="Secret Access Key" required />
    """
  end

  def provider_inputs(assigns), do: ~H||

  defp provider_regions("AWS"), do: ~w(us-east-1 us-east-2 us-west-1 us-west-2 ca-central-1)
  defp provider_regions(_), do: []

  @config_keys ~w(name environment region)
  defp get_form(provider, stack, config) do
    @config_keys
    |> Map.from_keys("")
    |> Map.merge(Map.take(config, @config_keys))
    |> add_provider_form_fields(provider, config)
    |> add_stack_form_fields(stack, config)
    |> to_form()
  end

  @aws_keys ~w(aws_access_key_id aws_secret_access_key)
  defp add_provider_form_fields(curr, "AWS", config) do
    curr
    |> Map.merge(Map.from_keys(@aws_keys, ""))
    |> Map.merge(Map.take(config, @aws_keys))
  end
  defp add_provider_form_fields(curr, _, _), do: curr

  defp add_stack_form_fields(curr, _, _), do: curr
end
