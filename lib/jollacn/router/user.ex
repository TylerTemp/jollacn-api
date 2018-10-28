defmodule JollaCNAPI.Router.User do
  use Plug.Router
  use Plug.ErrorHandler
  require Logger

  plug(Plug.Logger, log: :debug)
  # plug(Plug.Parsers.JSON)
  # plug Plug.Parsers,
  #   parsers: [:urlencoded, :json],
  #   pass: ["text/*"],
  #   json_decoder: Poison
  # plug(Plug.MethodOverride)
  plug(:match)
  plug(:dispatch)

  post "/login" do
    {:ok, body, conn} = read_body(conn)
    %{"name" => name, "password" => password} = :jiffy.decode(body, [:return_maps, :use_nil])

    sql = "SELECT * FROM \"user\" WHERE name = $1"
    args = [name]

    user =
      JollaCNAPI.DB.Repo
      |> Ecto.Adapters.SQL.query!(sql, args)
      # |> (fn(e) -> IO.inspect(e); e end).()
      |> JollaCNAPI.DB.Util.one(datetime: {"%F %T", "Asia/Shanghai", :strftime})

    case user do
      nil ->
        conn
        |> put_resp_header("Content-Type", "application/json")
        |> send_resp(
          400,
          :jiffy.encode(%{"message" => "user not found or password dismatch"}, [
            :use_nil
          ])
        )

      %{"password_encrypted" => password_encrypted} ->
        if Comeonin.Argon2.checkpw(password, password_encrypted) do
          now = Timex.now()
          iat = Timex.to_unix(now)

          exp =
            now
            |> Timex.shift(minutes: 10)
            |> Timex.to_unix()

          token =
            user
            |> Map.take(["id", "name", "permissions"])
            |> Map.merge(%{
              # expiration time
              "exp" => exp,
              # issue at
              "iat" => iat
            })
            |> jwt_sign(Application.fetch_env!(:jollacn_api, :jwt_secret))

          result =
            user
            |> Map.delete("password_encrypted")
            |> Map.put("jwt_token", token)

          # IO.inspect(result)

          conn
          |> put_resp_header("Content-Type", "application/json")
          |> send_resp(
            200,
            :jiffy.encode(
              result,
              [
                :use_nil
              ]
            )
          )
        else
          conn
          |> put_resp_header("Content-Type", "application/json")
          |> send_resp(
            400,
            :jiffy.encode(%{"message" => "user not found or password dismatch"}, [
              :use_nil
            ])
          )
        end
    end
  end

  def jwt_sign(payload, secret) do
    header = %{
      "alg" => "HS256",
      "typ" => "JWT"
    }

    [b64_header, b64_payload] =
      Enum.map([header, payload], fn dic ->
        dic
        |> :jiffy.encode([:use_nil])
        |> Base.url_encode64(padding: false)
      end)

    sign =
      :sha256
      |> :crypto.hmac(secret, "#{b64_header}.#{b64_payload}")
      |> Base.encode16()

    "#{b64_header}.#{b64_payload}.#{sign}"
  end

  match _ do
    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(
      404,
      :jiffy.encode(%{"message" => "page not found for #{conn.method} #{conn.request_path}"}, [
        :use_nil
      ])
    )
  end

  def handle_errors(conn, %{kind: _kind, reason: reason, stack: stack}) do
    Logger.error("SERVERERROR: #{inspect(reason)} : #{inspect(stack)}")

    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(500, :jiffy.encode(%{"message" => "server error"}, [:use_nil]))
  end
end
