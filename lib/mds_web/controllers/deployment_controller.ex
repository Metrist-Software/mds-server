defmodule MdsWeb.Controllers.DeploymentController do
  use MdsWeb, :controller
  require Logger

  def post(conn, %{"project_id" => project_id, "environment_id" => environment_id, "tag" => tag}) do
    allowed_account_ids = get_session(conn, :account_ids)

    with {:ok, project} <- get_and_validate_project(project_id, allowed_account_ids),
         {:ok, environment} <- get_and_validate_environment(environment_id, project_id)
    do
      {:ok, deployment} =
        MdsData.Deployments.create_deployment(
          project,
          environment,
          :app,
          :api,
          get_session(conn, :user_id),
          tag
        )

      Task.Supervisor.start_child(MdsServer.TaskSupervisor, fn ->
        try do
          MdsCore.Deployment.deploy(deployment, tag, self())
        rescue
          err ->
            Logger.error(Exception.format(:error, err, __STACKTRACE__))
        end
      end)

      send_resp(conn, 202, Jason.encode!(%{deployment_id: deployment.id}))
    else
      _err -> send_resp(conn, 404, Jason.encode!(%{error: "Not found"}))
    end
  end

  def post(conn, _params) do
    conn
    |> send_resp(400, Jason.encode!(%{message: "Invalid request"}))
  end

  defp get_and_validate_project(project_id, allowed_account_ids) do
    case MdsData.Projects.get_project(project_id) do
      %MdsData.Projects.Project{account_id: account_id} = project ->
        if account_id in allowed_account_ids do
          {:ok, project}
        else
          {:error, :not_allowed}
        end
      _ ->
        {:error, :not_found}
    end
  end

  defp get_and_validate_environment(environemnt_id, expected_project_id) do
    case MdsData.Projects.get_environment(environemnt_id) do
      %MdsData.Projects.Environment{project_id: ^expected_project_id} = environment ->
        {:ok, environment}
      _ ->
        {:error, :not_found}
    end
  end
end
