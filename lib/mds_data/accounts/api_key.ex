defmodule MdsData.Accounts.APIKey do
  use Ecto.Schema
  import Ecto.{Query, Changeset}

  @key_size 32

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "api_keys" do
    field :key, :string
    field :scope, Ecto.Enum, values: [:admin, :user, :account]
    field :scope_id, :binary_id

    timestamps()
  end

  def gen_api_key(%MdsData.Accounts.User{} = user) do
    key =
      @key_size
      |> :crypto.strong_rand_bytes()
      |> Base.encode32(padding: false)

    %__MODULE__{}
    |> change(
      key: key,
      scope: :user,
      scope_id: user.id
    )
  end

  def get_api_key(%MdsData.Accounts.User{} = user) do
    from k in __MODULE__,
      where: k.scope == :user and k.scope_id == ^user.id
  end

  def by_key(api_key_string) do
    from k in __MODULE__,
      where: k.key == ^api_key_string
  end
end
