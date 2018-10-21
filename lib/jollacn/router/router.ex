defmodule JollaCNAPI.Router do
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

  get "/" do
    version =
      case :application.get_key(:jollacn_api, :vsn) do
        {:ok, vsn} ->
          List.to_string(vsn)

        _error ->
          nil
      end

    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(
      200,
      :jiffy.encode(%{"env" => "#{Mix.env()}", "message" => "pong", "version" => version}, [
        :use_nil
      ])
    )
  end

  forward("/post", to: JollaCNAPI.Router.Post)
  forward("/tie", to: JollaCNAPI.Router.Tie)

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
