defmodule MdsData.Deployments.Deployment do
  use Ecto.Schema
  import Ecto.Changeset

  defmodule Log do
    @moduledoc """
    Helpers for constructing entries for the `log` field in the `deployments`
    table.
    """

    def info(msg, date \\ nil), do: do_log(:info, msg, date)
    def error(msg, error \\ nil, date \\ nil) do
      log = do_log(:error, msg, date)
      if is_nil(error)  do
        log
      else
        err_type = error.__struct__
        message = err_type.message(error)
        Map.put(log, "error", %{"type" => err_type, "message" => message})
      end
    end

    defp do_log(level, msg, date),
      do: %{
        "level" => level,
        "message" => msg,
        "date" => date || NaiveDateTime.utc_now()
      }
  end

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "deployments" do
    # TODO drop in schema field :reason, :string
    field :state, Ecto.Enum, values: [:new, :in_progress, :completed, :failed]
    field :state_data, :map
    field :source, Ecto.Enum, values: [:web, :api]
    field :kind, Ecto.Enum, values: [:infra, :app]
    # User or API key id
    field :source_id, :string
    field :tag, :string
    # Simplest for now but we probably want to rething this
    field :log, {:array, :map}
    belongs_to :project, MdsData.Projects.Project
    belongs_to :environment, MdsData.Projects.Environment

    timestamps()
  end

  @doc false
  def changeset(deployment, attrs) do
    deployment
    |> cast(attrs, [:project_id, :environment_id, :state, :state_data, :kind, :source_id, :source, :tag, :log])
    |> validate_required([:project_id, :environment_id, :kind, :source, :source_id])
  end
end
