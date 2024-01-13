defmodule MdsProviders.AWS.WebApp do
  @moduledoc """
  AWS Web applications. For now, we use EC2
  """
  require Logger
  alias MdsCore.Logging

  def gen(resource, deployment, target_dir) do
    Logger.info("Creating web application for #{deployment.project.name}")
    template = __MODULE__
    assigns = MdsCore.Deployment.std_assigns(deployment)

    assigns = Keyword.put(assigns, :region, deployment.environment.options["aws_region"])

    ssh_key = get_or_gen_ssh_public_key(resource, deployment)
    pub_file = Path.join(target_dir, "#{resource.id}.pub")
    File.write!(pub_file, ssh_key)
    assigns = Keyword.put(assigns, :pub_key_file, pub_file)

    assigns =
      if Map.has_key?(resource.options, "role_policy") do
        Keyword.merge(assigns,
          role_policy: MdsCore.Deployment.unpack_and_expand_user_template(resource.options["role_policy"], deployment),
          has_role_policy: true
        )
      else
        Keyword.put(assigns, :has_role_policy, false)
      end

    MdsCore.Deployment.expand(template, assigns, resource.id, target_dir)
  end

  def deploy(resource, deployment, version, target_dir, logging_pid) do
    cur_state =
      MdsData.Deployments.last_deployment_state(deployment.project, deployment.environment)
    cur_state = MdsCore.Environment.decrypt(cur_state, deployment.environment)

    output_value = fn name -> cur_state["outputs"][name]["value"] end

    # TODO technically we should ask the database to migrate. Or the database should ask us
    # to migrate. For now, it doesn't matter but if we ever have app-less databases or
    # database-less apps, it does.
    # TODO make this not hardcoded to Phoenix :)
    # TODO make this digging not necessary by using outputs?

    mds_env = MdsCore.Deployment.kebabize(deployment.environment.name)
    repo_url = output_value.("mds_webapp_container_repository")
    image = "#{repo_url}:#{version}"
    host_ip = output_value.("mds_webapp_instance_ip")
    aws_region = deployment.environment.options["aws_region"]
    secret_key_base = output_value.("mds_webapp_phx_secret")

    secret_key_base =
      "$(aws secretsmanager get-secret-value --region #{aws_region} --secret-id #{secret_key_base} | jq -r .SecretString | jq -r .key)"

    db_url = output_value.("mds_database_secret")

    db_url =
      """
      $(aws secretsmanager get-secret-value --region #{aws_region} --secret-id #{db_url} | jq -r .SecretString|jq -r '"ecto://\\(.user):\\(.pass)@\\(.host):\\(.port)/\\(.name)"') \
      """
      |> String.trim()

    public_dns = deployment.environment.options["hostname"]
    ssh_key_file = write_private_key(resource, deployment, target_dir)
    container_name = MdsCore.Deployment.kebabize(deployment.project.name)

    # TODO rename current version to old. We can ignore return values, if it fails, well,
    # the old version wasn't running.
    rename = "docker rename #{container_name} #{container_name}-old"

    docker_login =
      "aws ecr get-login-password --region #{aws_region} | docker login --username AWS --password-stdin #{repo_url}"

    docker_pull = "docker pull #{image}"

    phx_migrate = """
      docker run \
        -v ~/.aws:/root/.aws \
        -e SECRET_KEY_BASE=#{secret_key_base} \
        -e DATABASE_URL=#{db_url} \
        -e MDS_REGION=#{aws_region} \
        -e MDS_ENV=#{mds_env} \
        #{image} \
        /app/bin/migrate
    """

    webapp_run = """
      docker run -d \
        -v ~/.aws:/root/.aws \
        --name #{container_name} \
        --restart unless-stopped \
        -e SECRET_KEY_BASE=#{secret_key_base} \
        -e DATABASE_URL=#{db_url} \
        -e PHX_HOST=#{public_dns} \
        -e MDS_REGION=#{aws_region} \
        -e MDS_ENV=#{mds_env} \
        --label "traefik.http.routers.mds_server.rule=Host(\\`#{public_dns}\\`)" \
        --label "traefik.http.routers.mds_server.entrypoints=web" \
        --label "traefik.http.routers.mds_server.middlewares=https_redirect" \
        --label "traefik.http.routers.mds_server_secure.entrypoints=webSecure" \
        --label "traefik.http.routers.mds_server_secure.rule=Host(\\`#{public_dns}\\`)" \
        --label "traefik.http.routers.mds_server_secure.tls=true" \
        --label "traefik.http.routers.mds_server_secure.tls.certresolver=myresolver" \
        --label "traefik.http.services.mds_server_secure.loadbalancer.server.port=4000" \
        --label "traefik.http.middlewares.https_redirect.redirectscheme.scheme=https" \
        --label "traefik.http.middlewares.https_redirect.redirectscheme.permanent=true" \
        #{image} \
        /app/bin/server
    """

    stop_old = "docker stop #{container_name}-old"
    remove_old = "docker rm #{container_name}-old"

    # TODO host key handling. accept-new is a stopgap measure that will fail the second we replace
    # the EC2 instance.
    # TODO maybe erlexec can do this more reliable and cleaner?
    sess =
      Port.open(
        {:spawn,
         "ssh -tt -o StrictHostKeyChecking=accept-new -i #{ssh_key_file} ubuntu@#{host_ip}"},
        [:use_stdio, :stderr_to_stdout, :binary]
      )

    Process.sleep(5_000)

    prompt_token = :crypto.strong_rand_bytes(10) |> Base.encode32()
    send(sess, {self(), {:command, "PS1=\"#{prompt_token}>\"\n"}})
    wait_for(sess, prompt_token, logging_pid)
    send(sess, {self(), {:command, "#{docker_login}\n"}})
    wait_for(sess, prompt_token, logging_pid)
    send(sess, {self(), {:command, "#{docker_pull}\n"}})
    wait_for(sess, prompt_token, logging_pid)
    send(sess, {self(), {:command, "#{phx_migrate}\n"}})
    wait_for(sess, prompt_token, logging_pid)
    send(sess, {self(), {:command, "#{rename}\n"}})
    wait_for(sess, prompt_token, logging_pid)
    send(sess, {self(), {:command, "#{webapp_run}\n"}})
    wait_for(sess, prompt_token, logging_pid)
    # TODO check with Traefik (we can port-foward 8080) that all is well
    send(sess, {self(), {:command, "#{stop_old}\n"}})
    wait_for(sess, prompt_token, logging_pid)
    send(sess, {self(), {:command, "#{remove_old}\n"}})
    wait_for(sess, prompt_token, logging_pid)
  end

  def wait_for(sess, prompt_token, logging_pid) do
    receive do
      {^sess, {:data, data}} ->
        Logging.info(logging_pid, String.replace(data, prompt_token, ""))

        if not String.contains?(data, prompt_token) do
          wait_for(sess, prompt_token, logging_pid)
        end
    after
      30000 ->
        send(logging_pid, {:error, "No message received after half a minute", ""})
        raise "No message received after half a minute"
    end
  end

  def get_or_gen_ssh_private_key(resource, deployment) do
    decrypt_fn = fn v -> MdsCore.Environment.decrypt(v, deployment.environment) end
    encrypt_fn = fn v -> MdsCore.Environment.encrypt(v, deployment.environment) end

    state = MdsData.Deployments.get_resource_state(resource, deployment.environment)
    state = if not is_nil(state), do: %{state | state_values: decrypt_fn.(state.state_values)}

    if not is_nil(state) and Map.has_key?(state.state_values, "ssh_private_key") do
      state.state_values["ssh_private_key"]
    else
      # Nothing available, so we generate a key
      # TODO Encrypt with AWS Secret for the project/env combo
      priv_key = :public_key.generate_key({:rsa, 3072, 65537})
      entry = :public_key.pem_entry_encode(:RSAPrivateKey, priv_key)
      key = :public_key.pem_encode([entry])

      MdsData.Deployments.upsert_resource_state(resource, deployment, %{
        "ssh_private_key" => key
      }, decrypt_fn, encrypt_fn)

      key
    end
  end

  def get_or_gen_ssh_public_key(resource, deployment) do
    public_from_private(get_or_gen_ssh_private_key(resource, deployment))
  end

  def public_from_private(private_key) do
    [entry] = :public_key.pem_decode(private_key)
    private_key = :public_key.pem_entry_decode(entry)
    public_key = :ssh_file.extract_public_key(private_key)

    "ssh-rsa " <> (:ssh_file.encode(public_key, :ssh2_pubkey) |> Base.encode64())
  end

  def write_private_key(resource, deployment, target_dir) do
    private_key = get_or_gen_ssh_private_key(resource, deployment)
    filename = Path.join(target_dir, "id_rsa")

    File.touch!(filename)
    File.chmod!(filename, 0o600)
    File.write!(filename, private_key)

    filename
  end

end
