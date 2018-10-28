use Mix.Config

#     config :jollacn_api, key: :value
#     Application.get_env(:jollacn_api, :key)
#     config :logger, level: :info

config :jollacn_api, ecto_repos: [JollaCNAPI.DB.Repo]

config :jollacn_api, JollaCNAPI.DB.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "jollacn_api",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: "5432",
  log: :info

config :jollacn_api,
  port: 8082,
  jwt_secret: "example_jwt_secret"

config :logger,
  # handle_otp_reports: false,
  # backends: [{LoggerFileBackend, :json_log}]
  # backends: [:console]
  backends: [:console, {LoggerFileBackend, :file_log}]

config :logger, :file_log,
  format: "$date $time [$level] $message | $metadata\n",
  metadata: [except: [:pid, :file, :application]],
  path: "log/jollacn_api.log",
  level: :debug

config :logger, :console,
  format: "$date $time [$level] $message | $metadata\n",
  metadata: :all,
  level: :debug

case Mix.env() do
  prod_env = :prod ->
    IO.puts("force import config #{prod_env}.exs")
    import_config "#{prod_env}.exs"

  other_env ->
    file_name = "#{other_env}.exs"
    file_path = Path.join([__DIR__, file_name])

    if File.exists?(file_path) do
      import_config file_name
    else
      IO.puts("no such config #{file_path}, skip")
    end
end

#     import_config "#{Mix.env}.exs"
