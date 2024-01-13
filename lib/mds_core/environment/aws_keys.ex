defmodule MdsCore.Environment.AWSKeys do
  @moduledoc """
  Key management using AWS.
  """

  @doc """
  Retrieve or generate a key for the indicated environment. If `scheme` is not nil,
  allow generation, otherwise raise an error if the key can't be found.

  Returns a tuple `{scheme, key}` on success.
  """
  def key_for(environment, scheme \\ nil) do
    aws_key = MdsData.Secrets.get_secret("environments/#{environment.id}")
    path = "mds/environment_key/#{environment.id}"
    region = environment.options["aws_region"]

    case MdsData.Secrets.get_user_secret(path, aws_key, region) do
      nil ->
        if !is_nil(scheme) do
          secret = %{
            "scheme" => scheme,
            "key" => MdsCore.Environment.Crypt.make_key(scheme)
          }
          MdsData.Secrets.create_user_secret(path, secret, aws_key, region)
          {scheme, secret["key"]}

        else
          raise "Cannot find secret for environment #{environment.id}!"
        end

      secret ->
        {String.to_existing_atom(secret["scheme"]), secret["key"]}
    end
  end
end
