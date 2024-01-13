# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MdsData.Repo.insert!(%MdsData.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Assumes that you have a user in the DB
user = MdsData.Repo.one!(MdsData.Accounts.User)

{:ok, project} =
  MdsData.Projects.create_project(%{
    name: "local-project",
    creator_id: user.id,
    account_id: user.account_id
  })

%MdsData.Projects.Environment{
  id: "c0c4e411-dec1-4704-acbd-e6cb8a7ec8bb", # This UUID matches the secret in secrets manager
  name: "local-env",
  options: %{"aws_region" => "us-east-2", "hostname" => "staging.deploy.metri.st"},
  project_id: project.id,
  creator_id: user.id
}
|> MdsData.Repo.insert!()
