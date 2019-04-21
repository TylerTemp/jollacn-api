defmodule Mix.Tasks.User.Update do
  use Mix.Task

  def run([name | input_permissions]) do
    {:ok, _} = Application.ensure_all_started(:jollacn_api)

    permissions =
      if input_permissions == [":all"] do
        ["new_post", "update_post", "new_tie", "update_tie", "new_author", "update_author"]
      else
        input_permissions
      end

    result = JollaCNAPI.DB.Repo.transaction(fn ->
      sql = "
        UPDATE \"user\"
        SET permissions=$2
        WHERE name=$1
        RETURNING *
      "
      args = [name, permissions]

      user_updated = JollaCNAPI.DB.Repo
        |> Ecto.Adapters.SQL.query!(sql, args)
        |> JollaCNAPI.DB.Util.one()

      if user_updated == nil do
        JollaCNAPI.DB.Repo.rollback("user not found")
      end
      user_updated
    end)

    IO.inspect(result)
  end
end
