defmodule MdsWeb.SelfLive.Profile do
  use MdsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    accounts = MdsData.Accounts.accounts_for(socket.assigns.user)
    users = MdsData.Accounts.users_for(socket.assigns.account)

    socket =
      socket
      |> assign(accounts: accounts)
      |> assign(users: users)

    {:ok, socket}
  end

  @impl true
  def handle_event("change-name", %{"account_id" => id, "name" => name}, socket) do
    allowed_ids = Enum.map(socket.assigns.accounts, & &1.id)

    if id in allowed_ids do
      account = MdsData.Accounts.get_account!(id)
      MdsData.Accounts.update_account(account, %{name: name})
      accounts = MdsData.Accounts.accounts_for(socket.assigns.user)

      socket =
        socket
        |> assign(accounts: accounts)
        |> put_flash(:info, "Account name updated to #{name}.")

      {:noreply, socket}
    else
      socket =
        socket
        |> put_flash(:error, "You're not allowed to change this account.")

      {:noreply, socket}
    end
  end

  def handle_event("add-id", %{"uuid" => uuid}, socket) do
    case Ecto.UUID.cast(uuid) do
      {:ok, uuid} ->
        user = MdsData.Accounts.get_user(uuid)
        maybe_add_user(user, socket)

      :error ->
        socket =
          socket
          |> put_flash(:error, "Please enter a valid UUID")

        {:noreply, socket}
    end
  end

  def handle_event("add-email", %{"email" => email}, socket) do
    user = MdsData.Accounts.get_user_by_email(email)
    maybe_add_user(user, socket)
  end

  def handle_event("remove-user", %{"id" => id}, socket) do
    socket =
      cond do
        socket.assigns.user.id == id ->
          socket
          |> put_flash(:error, "Cannot remove yourself from account (yet).")

        Enum.count(socket.assigns.users) == 1 ->
          socket
          |> put_flash(:error, "Cannot remove last user from account (yet).")

        true ->
          existing_ids = Enum.map(socket.assigns.users, & &1.id)

          if id in existing_ids do
            MdsData.Accounts.remove_user_id_from_account(id, socket.assigns.account)
            users = MdsData.Accounts.users_for(socket.assigns.account)

            socket
            |> assign(users: users)
            |> put_flash(:info, "User removed.")
          else
            socket |> put_flash(:error, "User not found in account")
          end
      end

    {:noreply, socket}
  end

  defp maybe_add_user(nil, socket) do
    socket =
      socket
      |> put_flash(:error, "User not found, please verify your input")

    {:noreply, socket}
  end

  defp maybe_add_user(user, socket) do
    existing_ids = Enum.map(socket.assigns.users, & &1.id)

    if user.id in existing_ids do
      socket =
        socket
        |> put_flash(:error, "User already member of that account.")

      {:noreply, socket}
    else
      MdsData.Accounts.add_user_to_account_id(
        user,
        socket.assigns.account.id,
        socket.assigns.user.id
      )

      users = MdsData.Accounts.users_for(socket.assigns.account)

      socket =
        socket
        |> assign(users: users)
        |> put_flash(:info, "User added to account")

      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2>User information</h2>
      <table>
        <tr>
          <td>User id:</td>
          <td><%= @user.id %></td>
        </tr>
        <tr>
          <td>Email:</td>
          <td><%= @user.email %></td>
        </tr>
        <tr>
          <td>Logged in through:</td>
          <td><%= @user.provider %></td>
        </tr>
        <tr>
          <td>Primary account:</td>
          <td><%= @user.primary_account_id %></td>
        </tr>
        <tr>
          <td></td>
          <td><%= @account.name %></td>
        </tr>
      </table>
      <h2>Accounts</h2>
      <table>
        <tr>
          <td>Id</td>
          <td>Name</td>
        </tr>
        <%= for a <- @accounts do %>
          <tr>
            <td>
              <%= a.id %>
            </td>
            <td>
              <form phx-submit="change-name">
                <input type="hidden" name="account_id" value={a.id} />
                <input type="text" name="name" value={a.name} />
              </form>
            </td>
          </tr>
        <% end %>
      </table>
      <h2>Users in current active account <%= @account.id || @account.name %></h2>
      <table>
        <tr>
          <td>Id</td>
          <td>Name</td>
          <td></td>
        </tr>
        <%= for u <- @users do %>
          <tr>
            <td><%= u.id %></td>
            <td><%= u.email %></td>
            <td>
              <Heroicons.trash
                class="w-4 h-4 hover:cursor-pointer"
                phx-click="remove-user"
                phx-value-id={u.id}
              />
            </td>
          </tr>
        <% end %>
        <tr>
          <td>
            <form phx-submit="add-id">
              <input type="text" name="uuid" value="" placeholder="Enter UUID to add user" />
            </form>
          </td>
          <td>
            <form phx-submit="add-email">
              <input type="text" name="email" value="" placeholder="Enter Email to add user" />
            </form>
          </td>
          <td></td>
        </tr>
      </table>
    </div>
    """
  end
end
