defmodule MdsData.Projects.Resource do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "resources" do
    field :options, :map
    field :type, :string
    belongs_to :project, MdsData.Projects.Project
    field :creator_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:type, :options, :creator_id, :project_id])
    |> validate_required([:type, :options, :creator_id, :project_id])
  end

  def internalize_options(nil), do: %{}

  def internalize_options(options) do
    options
    |> String.split(",")
    |> Enum.reject(&Kernel.==(&1, ""))
    |> Enum.map(fn kv ->
      case String.split(kv, ":") do
        [k, v] -> {k, v}
        [other] -> {other, nil}
      end
    end)
    |> Map.new()
  end

  def externalize_options(options) do
    options
    |> Enum.map(fn {k, v} -> "#{k}:#{v}" end)
    |> Enum.join(",")
  end

  # Helpers

  def options(resource), do: resource.options
  def provider(resource), do: Map.get(options(resource), "provider")
end

# TODO this is a bit of a hack
defimpl Phoenix.HTML.Safe, for: Map do
  def to_iodata(map) do
    MdsData.Projects.Resource.externalize_options(map)
  end
end
