defmodule Mix.Tasks.User.List do
  use Mix.Task

  def run(_) do
    {:ok, _} = Application.ensure_all_started(:jollacn_api)

    sql = "SELECT * FROM \"user\""
    args = []

    user_list =
      JollaCNAPI.DB.Repo
      |> Ecto.Adapters.SQL.query!(sql, args)
      |> JollaCNAPI.DB.Util.all(datetime: {"%F %T", :strftime})

    Enum.each(user_list, fn user ->
      IO.puts("===============")

      user
      |> Map.delete("password_encrypted")
      # |> Enum.sort_by(fn({key, _value}) -> Enum.find_index(["id", "name"], key) end)
      |> Enum.each(fn
        {key, values} when is_list(values) ->
          IO.puts("#{key}: #{Enum.join(values, ", ")}")

        {key, value} ->
          IO.puts("#{key}: #{value}")
      end)
    end)
  end
end
