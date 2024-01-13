defmodule MdsWeb.Components.ProjectWizard.Provider do
  use MdsWeb, :live_component

  @providers [
    %{id: "AWS",          logo: "/images/logos/aws.svg",          available: true},
    %{id: "GCP",          logo: "/images/logos/gcp.svg",          available: false},
    %{id: "Azure",        logo: "/images/logos/azure.svg",        available: false},
    %{id: "DigitalOcean", logo: "/images/logos/digitalocean.svg", available: false}
  ]

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket,
      parent_id: assigns.parent_id,
      form: to_form(%{"provider" => assigns.state.provider || "AWS"}))}
  end

  @impl true
  def handle_event("submit", %{"provider" => provider}, socket) do
    send_update(MdsWeb.Components.ProjectWizard.Main, id: socket.assigns.parent_id, provider: provider, goto: :next)

    {:noreply, socket}
  end

  def handle_event("previous", _, socket) do
    send_update(MdsWeb.Components.ProjectWizard.Main, id: socket.assigns.parent_id, goto: :previous)

    {:noreply, socket}
  end

  defp providers(), do: @providers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2>Select Your Cloud Provider</h2>

      <.simple_form
        for={@form}
        id="provider-form"
        phx-target={@myself}
        phx-submit="submit"
      >
        <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
          <div :for={provider <- providers()} class="relative">
            <input
            type="radio"
            id={provider.id}
            name="provider"
            value={provider.id}
            class="hidden peer"
            disabled={!provider.available}
            checked={provider.id == @form[:provider].value}
            required
          />

            <label
              for={provider.id}
              class={"inline-flex rounded outline h-full w-full cursor-pointer outline-gray-400 peer-checked:outline-blue-500 peer-checked:outline-4 #{unless provider.available, do: "bg-gray-300"}"}
            >
              <img src={provider.logo} class={"p-3 m-auto rounded #{unless provider.available, do: "grayscale"}"}/>

              <p
                :if={!provider.available}
                class="absolute text-3xl font-bold text-white left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 text-center select-none drop-shadow-[0_1px_1px_rgba(0,0,0,0.8)]"
              >
                Coming Soon
              </p>
            </label>
          </div>
        </div>

        <:actions>
          <.button type="button" phx-click="previous" phx-target={@myself}>Previous</.button>
          <.button type="submit">Next</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
