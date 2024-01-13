defmodule MdsWeb.Components.ProjectWizard.Create do
  use MdsWeb, :live_component

  @impl true
  def update(_assigns, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <p>Setting up your project...</p>
    </div>
    """
  end
end
