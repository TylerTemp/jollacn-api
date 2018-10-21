defmodule JollaCNAPI.Seeds do
  require Logger

  def run() do
    if Mix.env() != :prod do
      :ok
    end
  end
end

IO.inspect(JollaCNAPI.Seeds.run())
