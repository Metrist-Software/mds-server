defmodule MdsData.Secrets do
  @moduledoc """
  Simple wrapper around secrets manager
  """
  require Logger

  @doc """
  Get a secret managed in the account where MDS is running. We store
  internal secrets here and the AWS keypair the user gave us for a
  particular environment.
  """
  def get_secret(path) do
    env = System.get_env("MDS_ENV", "localdev")
    region = System.get_env("MDS_REGION", "us-east-2")
    path = "mds/#{env}/mds-server/#{path}"

    result =
      path
      |> ExAws.SecretsManager.get_secret_value()
      |> ExAws.request(region: region)

    case result do
      {:ok, %{"SecretString" => secret}} ->
        Logger.info("Successfully fetched secret '#{path}'")
        Jason.decode!(secret)

      {:error, error} ->
        raise "Error getting secret '#{path}': #{inspect(error)}"
        nil
    end
  end

  @doc """
  Get a secret managed in a user's account.
  """
  def get_user_secret(path, aws_key, region) do
    result =
      path
      |> ExAws.SecretsManager.get_secret_value()
      |> ExAws.request(
        region: region,
        access_key_id: aws_key["aws_access_key_id"],
        secret_access_key: aws_key["aws_secret_access_key"]
      )

    case result do
      {:ok, %{"SecretString" => secret}} ->
        Jason.decode!(secret)

      {:error, _error} ->
        nil
    end

  end

  @doc """
  Create an MDS managed secret
  """
  def create_secret(path, value) when is_map(value) do
    env = System.get_env("MDS_ENV", "localdev")
    region = System.get_env("MDS_REGION", "us-east-2")
    path = "mds/#{env}/mds-server/#{path}"

    ExAws.SecretsManager.create_secret(
      client_request_token: Ecto.UUID.generate(),
      name: path,
      secret_string: Jason.encode!(value)
    )
    |> ExAws.request(region: region)
  end

  @doc """
  Create a user secret
  """
  def create_user_secret(path, value, aws_key, region) do
    result =
    ExAws.SecretsManager.create_secret(
      client_request_token: Ecto.UUID.generate(),
      name: path,
      secret_string: Jason.encode!(value)
    )
    |> ExAws.request(
      region: region,
      access_key_id: aws_key["aws_access_key_id"],
      secret_access_key: aws_key["aws_secret_access_key"]
    )

    case result do
      {:ok, _} ->
        :ok

      {:error, error} ->
        Logger.error("Could not create user secret, #{inspect error}")
        raise "Could not create user secret"
    end
  end

end
