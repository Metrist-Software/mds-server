defmodule MdsWeb.Components.ProjectWizard.Stack do
  use MdsWeb, :live_component

  @stacks [
    %{id: "rails",     logo: "/images/logos/rails.svg",     available: true},
    %{id: "phoenix",   logo: "/images/logos/phoenix.svg",   available: true},
    %{id: "django",    logo: "/images/logos/django.svg",    available: false},
    %{id: "express",   logo: "/images/logos/express.svg",   available: false},
    %{id: "wordpress", logo: "/images/logos/wordpress.svg", available: false}
  ]

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket,
      parent_id: assigns.parent_id,
      form: to_form(%{"stack" => assigns.state.stack || "rails"}))}
  end

  @impl true
  def handle_event("submit", %{"stack" => stack}, socket) do
    send_update(MdsWeb.Components.ProjectWizard.Main, id: socket.assigns.parent_id, stack: stack, goto: :next)

    {:noreply, socket}
  end

  defp stacks(), do: @stacks

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2>Select Your Stack</h2>

      <.simple_form
        for={@form}
        id="stack-form"
        phx-target={@myself}
        phx-submit="submit"
      >
        <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
          <div :for={stack <- stacks()} class="relative">
            <input
              type="radio"
              id={stack.id}
              name="stack"
              value={stack.id}
              class="hidden peer"
              disabled={!stack.available}
              checked={stack.id == @form[:stack].value}
              required
            />

            <label
              for={stack.id}
              class={"inline-flex rounded outline h-full w-full cursor-pointer outline-gray-400 peer-checked:outline-blue-500 peer-checked:outline-4 #{unless stack.available, do: "bg-gray-300"}"}
            >
              <img src={stack.logo} class={"p-3 m-auto rounded #{unless stack.available, do: "grayscale"}"}/>

              <p
                :if={!stack.available}
                class="absolute text-3xl font-bold text-white left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 text-center select-none drop-shadow-[0_1px_1px_rgba(0,0,0,0.8)]"
              >
                Coming Soon
              </p>
            </label>
          </div>
        </div>

        <:actions>
          <div /> <%!-- Empty div to push `Next` button to the right --%>
          <.button type="submit">Next</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
