defmodule MdsData.Repo do
  use Ecto.Repo,
    otp_app: :mds_server,
    adapter: Ecto.Adapters.Postgres
end
