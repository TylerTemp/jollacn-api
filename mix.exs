defmodule JollaCNAPI.MixProject do
  use Mix.Project

  def project do
    [
      app: :jollacn_api,
      version: "0.2.2",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [
        :logger,
        :plug_cowboy,
        # :cowboy,
        # :httpoison,
        :jiffy,
        :logger_file_backend,
        :ecto_sql,
        :postgrex,
        :decimal,
        :jason,
        # :quantum,
        :identicon,
        :egd,
        :timex,
        :eex,
        :calendar,
        :html_entities,
        :comeonin,
        :argon2_elixir
      ],
      mod: {JollaCNAPI.Application, []}
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:ecto_sql, "~> 3.0"},
      {:ecto_json, "~> 0.1.0"},
      {:postgrex, ">= 0.0.0"},
      #{:db_connection, "~> 2.0-pre"},
      {:jason, "~> 1.4"},
      # {:httpoison, "~> 1.0"},
      {:jiffy, "~> 1.1"},
      # {:hackney, path: "deps/hackney", override: true},
      # {:quantum, ">= 2.2.1"},
      {:timex, "~> 3.0"},
      {:decimal, "~> 2.0"},
      {:identicon, git: "https://github.com/Kociamber/identicon.git"},
      {:egd, github: "erlang/egd"},
      {:calendar, "~> 0.17.4"},
      {:html_entities, "~> 0.5"},
      # {:comeonin, "~> 4.0"},
      {:argon2_elixir, "~> 4.0"},
      {:logger_file_backend, git: "https://github.com/TylerTemp/logger_file_backend.git"},
      {:distillery, "~> 2.1", runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end

  defp aliases() do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
