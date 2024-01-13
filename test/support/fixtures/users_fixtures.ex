defmodule MdsData.UsersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MdsData.Users` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "some email",
        provider: "some provider",
        token: "some token"
      })
      |> MdsData.Users.create_user()

    user
  end
end
