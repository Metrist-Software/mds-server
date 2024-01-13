# Assumes that you have a user in the DB
user = MdsData.Repo.one!(MdsData.Accounts.User)

{:ok, project} =
  MdsData.Projects.create_project(%{
    name: "staging-project",
    creator_id: user.id,
    account_id: user.account_id
  })

environment =
  %MdsData.Projects.Environment{
    # This UUID matches the secret in secrets manager
    id: "c0c4e411-dec1-4704-acbd-e6cb8a7ec8bb",
    name: "staging-env",
    options: %{"aws_region" => "us-east-2", "hostname" => "staging.deploy.metri.st"},
    project_id: project.id,
    creator_id: user.id
  }
  |> MdsData.Repo.insert!()

%MdsData.Projects.Resource{
  options: %{
    "db" => "PostgreSQL",
    "instance_size" => "serverless",
    "provider" => "AWS"
  },
  type: "Database",
  project_id: project.id,
  creator_id: user.id
}
|> MdsData.Repo.insert!()

%MdsData.Projects.Resource{
  options: %{"provider" => "AWS", "region" => "us-east-2"},
  type: "Infrastructure",
  project_id: project.id,
  creator_id: user.id
}
|> MdsData.Repo.insert!()

{:ok, d} = MdsData.Deployments.create_deployment(project, environment, "Manual test")
