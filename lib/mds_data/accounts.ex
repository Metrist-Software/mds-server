defmodule MdsData.Accounts do
  @moduledoc """
  The Accounts context. Users, accounts, API keys, that sort of stuff.
  """

  import Ecto.Query, warn: false
  alias MdsData.Repo

  alias MdsData.Accounts.Account

  def list_accounts do
    Repo.all(Account)
  end

  def get_account!(id), do: Repo.get!(Account, id)

  def get_account_by_user!(user), do: Repo.get!(Account, user.primary_account_id)

  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  def change_account(%Account{} = account, attrs \\ %{}) do
    Account.changeset(account, attrs)
  end

  alias MdsData.Accounts.User

  def list_users do
    Repo.all(User)
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_user(id), do: Repo.get(User, id)

  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  alias MdsData.Accounts.APIKey

  def gen_api_key(%User{} = user) do
    user
    |> APIKey.gen_api_key()
    |> Repo.insert()
  end

  def get_api_key(%User{} = user) do
    user
    |> APIKey.get_api_key()
    |> Repo.one()
  end

  def get_owner(api_key_string) do
    case Repo.one(APIKey.by_key(api_key_string)) do
      nil ->
        nil

      api_key ->
        case api_key.scope do
          :user ->
            get_user!(api_key.scope_id)

          _ ->
            raise "Unsupported API key type #{api_key.scope}"
        end
    end
  end

  alias MdsData.Accounts.UserAccount

  def account_ids_for(user) do
    query =
      from ua in UserAccount,
        where: ua.user_id == ^user.id,
        select: ua.account_id

    Repo.all(query)
  end

  def add_user_to_account_id(user, account_id, creator_id \\ nil) do
    %UserAccount{}
    |> Ecto.Changeset.change(
      user_id: user.id,
      account_id: account_id,
      creator_id: creator_id || user.id
    )
    |> Repo.insert()
  end

  def remove_user_id_from_account(user_id, account) do
    query =
      from ua in UserAccount,
        where: ua.user_id == ^user_id and ua.account_id == ^account.id

    Repo.delete_all(query)
  end

  def accounts_for(user) do
    Repo.all(Ecto.assoc(user, :accounts))
  end

  def users_for(account) do
    Repo.all(Ecto.assoc(account, :users))
  end
end
