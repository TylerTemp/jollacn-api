defmodule Mix.Tasks.User.Add do
  use Mix.Task

  def run([name | input_permissions]) do
    {:ok, _} = Application.ensure_all_started(:jollacn_api)

    permissions =
      if input_permissions == [":all"] do
        ["new_post", "update_post", "new_tie", "update_tie"]
      else
        input_permissions
      end

    password = "Input your password (WILL echo back when input!):\n" |> IO.gets() |> String.trim()

    user = %{
      "name" => name,
      "password" => password,
      "permissions" => permissions
    }

    IO.puts("user: #{inspect(user)}")

    changes =
      user
      |> Map.delete("password")
      |> Map.put("password_encrypted", Comeonin.Argon2.hashpwsalt(password))

    %JollaCNAPI.DB.Model.User{}
    |> JollaCNAPI.DB.Model.User.changeset(changes)
    |> JollaCNAPI.DB.Repo.insert!()
    |> Map.drop([:__meta__, :__struct__])
    |> IO.inspect()
  end
end
