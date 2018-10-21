defmodule JollaCNAPI.DB.Repo do
  use Ecto.Repo,
    otp_app: :jollacn_api,
    adapter: Ecto.Adapters.Postgres
end
