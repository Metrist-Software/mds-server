defmodule MdsCore.Environment do
  @moduledoc """
  Core functionality for an environment.

  ## Encryption

  Some data gets encrypted with keys that we store in Secrets Manager in the user's AWS account. This
  way, the user keeps control over project-specific secrets.

  Encryption is - by design - not transparent, code that requires access to this data needs to
  explicitly call the decryption function; code that wants to change the data needs to explicitly
  call encryption before sending it to the database. This allows us to keep the availability
  of cleartext to the absolute minimum and to track the cases where this happens.

  Currently, we encrypt the following:

  - Deployment: state_data. This is Terraform state and TF will store generated passwords here.
  - Resource state: state_values. This is where we store a generated SSH key to access EC2
    instances.
  """

  defdelegate encrypt(value, environment), to: MdsCore.Environment.Crypt
  defdelegate decrypt(value, environment), to: MdsCore.Environment.Crypt
end
