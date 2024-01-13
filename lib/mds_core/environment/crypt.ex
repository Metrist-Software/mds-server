defmodule MdsCore.Environment.Crypt do
  @moduledoc """
  Encryption and decryption of data. For now, this is hardcoded to AWS
  projects. We can change that by relying on project/environment configuration
  later on.

  We tag all data with a cleartext marker "MDSE", so we can recognize
  "legacy" unencrypted data and respond correctly. Following the cleartext
  marker is a two byte version marker.

  Data is (currently) encrypted using AES256 in CBC mode with a random IV. The key is
  generated on the fly when needed and stored in the project's
  account; that way, secrets are under the user's control, not ours. If a user does not
  want to use our stuff anymore, they can delete the secrets and cancel their account and
  continue using the infrastructure if they wish as we won't have access to it anymore.

  To keep things simple, stuff like key rotation, BYOK, is not part of the
  functionality at the moment.

  Note that at the moment, we only support JSON data (as that is all we need to encrypt).
  """

  @scheme :aes_256_cbc
  @cur_ver "0"

  # This code got very much copy/pasted from Metrist backend crypt_utils.ex.

  def encrypt(nil, _environment), do: nil
  def encrypt(map, _environment) when is_map(map) and map_size(map) == 0, do: %{}
  def encrypt(map, environment) when is_map(map) do
    do_encrypt(map, environment, @scheme)
  end

  def decrypt(%{"mds_encrypted" => true} = encrypted, environment) do
    do_decrypt(encrypted, environment)
  end
  def decrypt(cleartext, _environment), do: cleartext

  def make_key(scheme), do: gen_random(key_bytes(scheme))

  # Default encryption scheme.
  defp do_encrypt(map, environment, scheme) do
    {scheme, key} = MdsCore.Environment.AWSKeys.key_for(environment, scheme)
    data = Jason.encode!(map)
    iv = gen_random(iv_bytes(scheme))
    real_key = decode(key, key_bytes(scheme))
    real_iv = decode(iv, iv_bytes(scheme))
    real_encrypted = :crypto.crypto_one_time(scheme, real_key, real_iv,
      data, encrypt: true, padding: :random)
    encrypted = Base.encode64(real_encrypted)
    %{
      "mds_encrypted" => true,
      "version" => @cur_ver,
      "iv" => iv,
      "length" => String.length(data),
      "ciphertext" => encrypted
    }
  end

  ############
  # Scheme 0
  #
  # We store iv:length:bytes, one key per environment, everything
  # is base64 encoded.
  #
  defp do_decrypt(%{"version" => "0"} = encrypted, environment) do
    {scheme, key} = MdsCore.Environment.AWSKeys.key_for(environment)

    real_key = decode(key, key_bytes(scheme))
    real_iv = decode(encrypted["iv"], iv_bytes(scheme))
    real_encrypted = decode(encrypted["ciphertext"])
    real_encrypted_size = :erlang.byte_size(real_encrypted)
    # Left pad our encrypted data to a full block
    block_size = block_size(scheme)
    real_encrypted =
      case Integer.mod(real_encrypted_size, block_size) do
        0 ->
          # Round block, we can use it as is
          real_encrypted
        _ ->
          # Left pad up to the next round block size
          padded_size = (div(real_encrypted_size, block_size) + 1) * block_size
          binary_pad_left(real_encrypted, padded_size)
      end
    real_decrypted = :crypto.crypto_one_time(
      scheme,
      real_key,
      real_iv,
      real_encrypted,
      encrypt: false, padding: :random
    )

    length = encrypted["length"]
    cleartext = :binary.part(real_decrypted, 0, length)
    Jason.decode!(cleartext)
  end

  # Helpers.

  defp iv_bytes(scheme) do
    :crypto.cipher_info(scheme).iv_length
  end

  defp key_bytes(scheme) do
    :crypto.cipher_info(scheme).key_length
  end

  defp block_size(scheme) do
    :crypto.cipher_info(scheme).block_size
  end

  defp gen_random(bytes) do
    bytes
    |> :crypto.strong_rand_bytes()
    |> Base.encode64()
  end

  defp decode(external) do
    Base.decode64!(external)
  end
  defp decode(external, expected_bytes) do
    # Random numbers may start with a 0 and the encoding above will slice that off. So we
    # pad left with zeros and take as many bytes on the right as we need.
    decoded = decode(external)
    binary_pad_left(decoded, expected_bytes)
  end

  defp binary_pad_left(decoded, expected_bytes) do
    bit_size = expected_bytes * 8
    padded = << 0::size(bit_size), decoded::binary >>
    :binary.part(padded, {byte_size(padded), -expected_bytes})
  end
end
