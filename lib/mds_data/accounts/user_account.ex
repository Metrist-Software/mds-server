defmodule MdsData.Accounts.UserAccount do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users_accounts" do
    field :user_id, :binary_id
    field :account_id, :binary_id

    field :creator_id, :binary_id
    timestamps()
  end

  @doc false
  def changeset(users_accounts, attrs) do
    users_accounts
    |> cast(attrs, [])
    |> validate_required([])
  end
end
