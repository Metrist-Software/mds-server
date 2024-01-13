defmodule MdsWeb.Controllers.AuthController do
  use MdsWeb, :controller

  require Logger
  plug Ueberauth

  def callback(%{assigns: %{ueberauth_failure: fails}} = conn, _params) do
    Logger.error("Authentication failure: #{inspect(fails)}")

    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user_data = %{
      token: auth.credentials.token,
      email: auth.info.email,
      provider: Atom.to_string(auth.provider)
    }

    case findOrCreateUser(user_data) do
      {:ok, user} ->
        account = MdsData.Accounts.get_account_by_user!(user)

        conn
        |> put_flash(:info, "Thanks for logging in - have fun!")
        |> put_session(:user, user)
        |> put_session(:account, account)
        |> redirect(to: "/")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Something went wrong")
        |> redirect(to: "/")
    end
  end

  def signout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

  defp findOrCreateUser(user_data) do
    alias MdsData.Accounts.{User, Account, UserAccount}
    alias MdsData.Repo

    changeset = User.changeset(%User{}, user_data)

    case MdsData.Accounts.get_user_by_email(changeset.changes.email) do
      nil ->
        IO.puts("User not found, creating new user and account")

        Repo.transaction(fn ->
          account = %Account{}
          user_account = %UserAccount{}

          with {:ok, account} <- Repo.insert(account),
               changeset <- Ecto.Changeset.change(changeset, primary_account_id: account.id),
               {:ok, user} <- Repo.insert(changeset),
               changeset <- Ecto.Changeset.change(account, owner_id: user.id, name: user.email),
               {:ok, account} <- Repo.update(changeset),
               changeset <-
                 Ecto.Changeset.change(user_account,
                   creator_id: user.id,
                   user_id: user.id,
                   account_id: account.id
                 ),
               {:ok, _} <- Repo.insert(changeset) do
            MdsData.Accounts.gen_api_key(user)
            user
          end
        end)

      user ->
        # Temporary to convert users on the fly from "can have one account" to "can have multiple".
        # If we have a primary account id but no link record, we add one.
        case MdsData.Accounts.account_ids_for(user) do
          [] ->
            MdsData.Accounts.add_user_to_account_id(user, user.primary_account_id)
          _accounts ->
            :ok
        end

        {:ok, user}
    end
  end
end
