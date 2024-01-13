# MdsData

PoC/Prototype/Spike for easy deploys.

## Design

Use best-of-breed tools instead of reinventing wheels.

* Terraform can do infra deployments.
* Traefik can help in roll-outs
* Native database migrations.
* Elixir glue.

We define apps in Elixir, then have Terraform snippets generated (yay for
Terraform just hovering up anything it sees in the current dir) and that
gets applied.

We stay somewhat close to the Terraform model: a _Project_ is the whole top level thing,
which probably later on can have one or many applications but for now it's a single flat thing with a set of _Resources_ that define where code lives, what providers to use, etc. These
resources are deployed to one or more _Environments_ (staging, production, things like that).

A _Deployment_ is a Terraform thing. We step through all the resources and let them generate
Terraform code snippets in a temporary directory, then drop existing state (if available) there
and run Terraform. Once done, we import the state back into the deployment - we hand it back to
the resources to get parsed and converted into _ResourceState_ records, which are essentially
a database version of Terraform outputs for quick access.

## First goal

Deploy this code with itself.

## Setup

Add a section to `~/.aws/config`:

    [profile mds]
    sso_start_url = https://metrist-software.awsapps.com/start
    sso_region = us-west-2
    sso_account_id = 304682015423
    sso_role_name = AdministratorAccess
    region = us-east-2

You really want to use `direnv` to make use of the included `.envrc` file - it
sets some important things and keeps your machine clean.
