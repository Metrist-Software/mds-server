defmodule MdsCore.Deployment do
  @moduledoc """
  Code handling an actual deployment.
  """

  require Logger
  alias MdsCore.Logging

  @doc """
  Bring infrastructure up.
  """
  def up(deployment, output_pid) do
    {:ok, logging_pid} = Logging.start_link(output_pid, deployment.id)

    deployment =
      try do
        deployment = refresh_from_database(deployment)

        {:ok, deployment} =
          MdsData.Deployments.update_deployment(deployment, %{state: :in_progress})

        # TODO locking - we can only run any given deployment once
        put_secrets_in_process_dict(deployment.environment)

        remove_deploy_dir(deployment)
        make_deploy_dir(deployment)
        generate(deployment)
        dump_current_state(deployment)

        deployment
      rescue
        err ->
          Logger.error(Exception.format(:error, err, __STACKTRACE__))
          Logging.error(logging_pid, "Error during setup", err)
          {:ok, _deployment} =
            MdsData.Deployments.update_deployment(deployment, %{state: :failed})
          raise err
      end

    retval =
      try do
        run_terraform(deployment, logging_pid)
        # TODO it is critical to always have the latest state, but we probably want to do more,
        # like checking serial numbers. As long as we have good statefile management, nothing
        # will break (famous last words)
        state_data = import_state_data(deployment)

        {:ok, _deployment} =
          MdsData.Deployments.update_deployment(deployment, %{
            state: :completed,
            state_data: state_data
          })

        Logger.info("Terraform output state version #{state_data["serial"]}")
        :ok
      rescue
        err ->
          MdsData.Deployments.update_deployment(deployment, %{state: :failed})
          Logger.error(Exception.format(:error, err, __STACKTRACE__))
          Logging.error(logging_pid, "Error during deployment", err)
          :error
      end

    if retval == :ok do
      # At some point we probably always want to remove it
      remove_deploy_dir(deployment)
    end

    retval
  end

  @doc """
  Destroy infrastructure.
  """
  def down(deployment, output_pid) do
    {:ok, logging_pid} = Logging.start_link(output_pid, deployment.id)

    deployment =
      try do
        deployment = refresh_from_database(deployment)

        {:ok, deployment} =
          MdsData.Deployments.update_deployment(deployment, %{state: :in_progress})

        # TODO locking - we can only run any given deployment once
        put_secrets_in_process_dict(deployment.environment)

        remove_deploy_dir(deployment)
        make_deploy_dir(deployment)
        generate(deployment)
        dump_current_state(deployment)

        deployment
      rescue
        err ->
          Logging.error(logging_pid, "Error during setup", err)
        raise err
      end

    retval =
      try do
        run_terraform(deployment, logging_pid, destroy: true)
        :ok
      rescue
        err ->
          Logger.error(Exception.format(:error, err, __STACKTRACE__))
          Logging.error(logging_pid, "Error during deployment", err)
          :error
      after
        # TODO it is critical to always have the latest state, but we probably want to do more,
        # like checking serial numbers. As long as we have good statefile management, nothing
        # will break (famous last words)
        state_data = import_state_data(deployment)

        {:ok, _deployment} =
          MdsData.Deployments.update_deployment(deployment, %{
            state: :completed,
            state_data: state_data
          })

        Logger.info("Terraform output state version #{state_data["serial"]}")
      end

    if retval == :ok do
      # At some point we probably always want to remove it
      remove_deploy_dir(deployment)
    end

    retval
  end

  @doc """
  Deploy an application version.
  """
  def deploy(deployment, version, output_pid) do
    {:ok, logging_pid} = Logging.start_link(output_pid, deployment.id)
    deployment = refresh_from_database(deployment)

    # TODO locking - we can only run any given deployment once
    make_deploy_dir(deployment)
    put_secrets_in_process_dict(deployment.environment)

    try do
      MdsData.Deployments.update_deployment(deployment, %{state: :in_progress})

      deployment
      |> order_resources()
      |> Enum.map(fn {t, _reqs, r} ->
        Logging.info(logging_pid, "=== Deploying #{r.type}")
        t.deploy(r, deployment, version, deploy_dir(deployment), logging_pid)
        Logging.info(logging_pid, "=== Completed #{r.type}")
      end)

      MdsData.Deployments.update_deployment(deployment, %{state: :completed})
    rescue
      err ->
        MdsData.Deployments.update_deployment(deployment, %{state: :failed})
        Logger.error(Exception.format(:error, err, __STACKTRACE__))
        Logging.error(logging_pid, "Error during deployment", err)
        raise err
    after
      remove_deploy_dir(deployment)
    end

    :ok
  end

  def refresh_from_database(deployment) do
    # It is critical that we have the latest version from the database in case we missed
    # a terraform update. The preload will pull in everything we need for the deployment.
    deployment.id
    |> MdsData.Deployments.get_deployment!()
    |> MdsData.Deployments.full_preload_deployment()
  end

  def generate(deployment) do
    deployment.project.resources
    |> Enum.map(fn r ->
      type = MdsCore.Resource.type_of(r.type)
      type.gen(r, deployment, deploy_dir(deployment))
    end)
  end

  # TODO a lot of this can be done at compile time probably
  # and certainly a bit more efficient. For now, we have small
  # amounts of resources so this is fine.
  def order_resources(deployment) do
    deployment.project.resources
    |> Enum.map(fn r ->
      t = MdsCore.Resource.type_of(r.type)
      {t, t.required_resources(), r}
    end)
    |> topo_sort()
  end

  # public for testing.
  def topo_sort(items) do
    items
    |> Enum.reduce(Graph.new(), fn {t, reqs, _}, graph ->
      g = Graph.add_vertex(graph, t)
      Enum.reduce(reqs, g, fn r, g -> Graph.add_edge(g, r, t) end)
    end)
    |> Graph.topsort()
    |> Enum.map(fn t ->
      Enum.find(items, fn {it, _, _} -> t == it end)
    end)
  end

  def make_deploy_dir(deployment) do
    deployment
    |> deploy_dir()
    |> File.mkdir_p!()
  end

  defp deploy_dir(deployment) do
    Path.join([
      MdsServer.Application.tmp_dir(),
      "mds-server",
      "deploys",
      deployment.id
    ])
  end

  defp remove_deploy_dir(deployment) do
    deployment
    |> deploy_dir()
    |> File.rm_rf!()
  end

  def dump_current_state(deployment) do
    # TODO repair state: if there's a deployment directory, and it is for current
    # project/env, and it has a state with serial newer than what we find here, then
    # import that state and use it. It means we crashed before we could import state.
    case MdsData.Deployments.last_deployment_state(deployment.project, deployment.environment) do
      nil ->
        :ok

      state_data ->
        state_data = MdsCore.Environment.decrypt(state_data, deployment.environment)
        state_filename = Path.join(deploy_dir(deployment), "terraform.tfstate")
        File.write!(state_filename, Jason.encode!(state_data))
        Logger.info("Terraform input state version #{state_data["serial"]}")
    end
  end

  def import_state_data(deployment) do
    deployment
    |> deploy_dir()
    |> Path.join("terraform.tfstate")
    |> File.read!()
    |> Jason.decode!()
    |> MdsCore.Environment.encrypt(deployment.environment)
  end

  defp run_terraform(deployment, logging_pid, opts \\ []) do
    destroy = Keyword.get(opts, :destroy, false)
    terraform = find_terraform()

    os = Logging.stream(logging_pid)

    # TODO other things than AWS
    aws_access_key_id = get_secret_value("aws_access_key_id")
    aws_secret_access_key = get_secret_value("aws_secret_access_key")
    # TODO better executable handling, e.g. :erlexec
    # TODO error handling, streaming output, etc.
    # TODO stash .terraform.lock.hcl and write it out again.
    {_out, exit} =
      System.cmd(terraform, ["init", "-no-color"],
        cd: deploy_dir(deployment),
        stderr_to_stdout: true,
        into: os
      )

    if exit != 0 do
      raise "Terraform exited with unexpected exit value #{exit}"
    end

    tf_flags = ["-auto-approve", "-no-color"]

    tf_flags =
      if destroy do
        ["-destroy" | tf_flags]
      else
        tf_flags
      end

    {_out, exit} =
      System.cmd(terraform, ["apply" | tf_flags],
        cd: deploy_dir(deployment),
        env: [
          {"AWS_ACCESS_KEY_ID", aws_access_key_id},
          {"AWS_SECRET_ACCESS_KEY", aws_secret_access_key}
        ],
        stderr_to_stdout: true,
        into: os
      )

    if exit != 0 do
      raise "Terraform exited with unexpected exit value #{exit}"
    end
  end

  # In case of emergency, dig around in the TF state
  def state_record(deployment, record_type) do
    case Enum.find(deployment.state_data["resources"], fn r -> r["type"] == record_type end) do
      nil -> nil
      hit -> Enum.at(hit["instances"], 0)
    end
  end

  def output_value(deployment, value) do
    outputs = deployment.state_data["outputs"]

    case outputs[value] do
      nil -> nil
      v -> v["value"]
    end
  end

  defp find_terraform do
    try do
      case System.cmd("asdf", ["which", "terraform"]) do
        {tf, 0} ->
          String.trim(tf)

        _ ->
          "terraform"
      end
    rescue
      _ -> "terraform"
    end
  end

  # We stash the secrets in the process dict so that we don't need to
  # pass them around all the time.
  defp put_secrets_in_process_dict(environment) do
    secrets = MdsData.Secrets.get_secret("environments/#{environment.id}")
    Process.put(:secrets, secrets)
  end

  def get_secret_value(key) do
    secrets = Process.get(:secrets)
    Map.get(secrets, "#{key}")
  end

  def pe_tag(deployment) do
    "mds_#{deployment.environment.name}_#{deployment.project.name}"
    |> underscoreize()
  end

  def underscoreize(s) do
    s
    |> String.downcase()
    |> String.replace(~r/[\W]+/, "_")
  end

  def kebabize(s) do
    s
    |> underscoreize()
    |> String.replace("_", "-")
  end

  def smash(s) do
    s
    |> underscoreize()
    |> String.replace("_", "")
  end

  def expand(template, assigns, target_id, target_dir) do
    template_file =
      Path.join([
        Application.app_dir(:mds_server, "priv"),
        "tft",
        "#{template}.tft"
      ])

    rendered = EEx.eval_file(template_file, assigns: assigns)

    out_file =
      Path.join([
        target_dir,
        "#{template}-#{target_id}.tf"
      ])

    File.write!(out_file, rendered)
  end

  @doc """
  User-editable/visible templates are rendered using Moustache. This is simpler
  and infinitely safer than trying to sandbox EEx or similar.
  """
  def unpack_and_expand_user_template(user_template, deployment) do
    user_template
    |> Base.decode64!(ignore: :whitespace)
    |> :bbmustache.render(std_assigns(deployment), key_type: :atom)
  end

  def std_assigns(deployment) do
    env = deployment.environment.name
    project = deployment.project.name
    pe_tag = pe_tag(deployment)

    [
      pe_tag: pe_tag,
      pe_tag_kebab: kebabize(pe_tag),
      pe_tag_smashed: smash(pe_tag),
      project_name: project,
      project: underscoreize(project),
      project_kebab: kebabize(project),
      env_kebab: kebabize(env),
      env: underscoreize(env),
      default_tags: """
        CreatedBy          = "Metrist Deployer/Terraform"
        MdsProjectName     = "#{project}"
        MdsProjectId       = "#{deployment.project.id}"
        MdsEnvironmentName = "#{env}"
        MdsEnvironmentId   = "#{deployment.environment.id}"
        MdsTag             = "#{pe_tag}"
      """
    ]
  end
end
