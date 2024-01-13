defmodule MdsProviders.AWS do
  require Logger

  def execute(ex_aws_cmd, environment, config_overrides \\ []) do
    region = Map.get(environment.options, "aws_region", "us-west-2")


    config = Keyword.merge([
        access_key_id: MdsCore.Deployment.get_secret_value(:aws_access_key_id),
        secrect_access_key: MdsCore.Deployment.get_secret_value(:aws_secret_access_key),
        region: region
    ], config_overrides)

    Logger.debug("AWS >>> #{inspect(ex_aws_cmd)}")
    #Logger.debug("AWS >>> #{inspect config}")

    result =
      ExAws.request(ex_aws_cmd,
        config
      )

    case result do
      {:ok, %{body: body, headers: headers, status_code: 200}} ->
        Logger.debug("AWS <<< #{inspect(body)}")

        {:ok, process_body(content_type(headers), body)}

      {:ok, parsed_body} ->
        Logger.debug("AWS <<< #{inspect(parsed_body)}")

        {:ok, parsed_body}

      {:error, {:http_error, 400, %{body: body, headers: headers}}} ->
        Logger.error("AWS!<<< #{inspect(body)}")

        {:ok, process_body(content_type(headers), body)}
        {:error, {:aws, process_body(content_type(headers), body)}}

      {:error, error} ->
        Logger.error("AWS error: #{inspect(error)}")
        {:error, error}
    end
  end

  defp content_type(headers) do
    header_map =
      headers
      |> Enum.map(fn {k, v} -> {String.downcase(k), v} end)
      |> Map.new()

    Map.get(header_map, "content-type")
  end
  defp process_body(<<"text/xml", _::binary>>, body) do
    XmlToMap.naive_map(body)
  end

  defp process_body(other, body) do
    Logger.warn("No handler for content type #{other}, returning body as is")
    body
  end

  @doc """
  Wait until a resource is available or similar. This probably
  can live in a separate module at some point.
  """
  def wait_for(function, tries_left \\ 10)

  def wait_for(_function, 0),
    do: {:error, "Timed out while waiting for resource to become available"}

  def wait_for(function, tries_left) do
    if function.() do
      :ok
    else
      Logger.info("Resource not yet available, sleeping (tries left #{tries_left})")
      Process.sleep(10_000)
      wait_for(function, tries_left - 1)
    end
  end
end
