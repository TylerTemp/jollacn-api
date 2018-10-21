defmodule JollaCNAPI.Application do
  @moduledoc false

  use Application
  require Logger
  import Supervisor.Spec

  def start(_type, _args) do
    port =
      case Application.fetch_env!(:jollacn_api, :port) do
        p when is_integer(p) ->
          p

        system_env ->
          Logger.debug("getting port from #{system_env} var")
          String.to_integer(System.get_env("#{system_env}"))
      end

    children = [
      Plug.Cowboy.child_spec(scheme: :http, plug: JollaCNAPI.Router, options: [port: port]),
      supervisor(JollaCNAPI.DB.Repo, [])
    ]

    Logger.info("starting server http://localhost:#{port}")
    opts = [strategy: :one_for_one, name: JollaCNAPI.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
