defmodule MdsWeb.SelfLive.ChangeAccount do
  use MdsWeb, :live_view

  @impl true
  def mount(_param, _session, socket) do
    accounts = MdsData.Accounts.accounts_for(socket.assigns.user)
    socket = assign(socket, accounts: accounts)
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      Choose an account to switch to:
      <ul>
        <%= for a <- @accounts do %>
          <li><a href={~p"/self/do_change_account/#{a.id}"}><%= a.name || a.id %></a></li>
        <% end %>
      </ul>
    </div>
    """
  end
end
