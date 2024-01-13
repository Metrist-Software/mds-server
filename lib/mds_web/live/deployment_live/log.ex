defmodule MdsWeb.DeploymentLive.Log do
  use MdsWeb, :live_view
  import MdsWeb.Live.ProjectAccess, only: [if_accessible_project: 1]

  @impl true
  def mount(params, _session, socket) do
    # A bit roundabout but this way we can reuse if_accessible_project
    deployment = MdsData.Deployments.get_deployment!(params["deployment_id"])
    params = Map.put(params, "project_id", deployment.project_id)

    socket =
      if_accessible_project do
        socket
        |> assign(deployment: deployment)
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <table>
      <tr>
        <th></th>
        <th></th>
      </tr>
      <%= for l <- @deployment.log do %>
        <tr>
          <td class="align-top text-xs pt-2"><%= l["date"] %></td>
          <td><%= format_entry(l) %></td>
        </tr>
      <% end %>
    </table>
    """
  end

  def format_entry(%{"level" => "info", "message" => msg}) do
    assigns = %{msg: msg}

    ~H"""
    <pre><%= @msg %></pre>
    """
  end

  def format_entry(%{"level" => "error", "message" => msg, "error" => error}) do
    assigns = %{msg: msg, error: error}

    ~H"""
    <div class="text-red-800 mt-2 pl-2">
      <%= @error["type"] %>: <%= @msg %>: <%= @error["message"] %>
    </div>
    """
  end
end
