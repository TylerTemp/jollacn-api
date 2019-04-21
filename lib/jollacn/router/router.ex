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
  plug(JollaCNAPI.Plug.Auth,
    path: [
      %{method: :post, path: "post", permission: %{must: ["new_post"]}},
      %{method: :patch, path: "post", permission: %{must: ["update_post"]}},
      %{method: :post, path: "tie", permission: %{must: ["new_tie"]}},
      %{method: :patch, path: "tie", permission: %{must: ["update_tie"]}},
      %{method: :post, path: "author", permission: %{must: ["new_author"]}},
      %{method: :patch, path: "author", permission: %{must: ["update_author"]}},
    ]
  )

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

    env = Application.get_env(:jollacn_api, :env, nil)

    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(
      200,
      :jiffy.encode(%{"env" => "#{env}", "message" => "pong", "version" => version}, [
        :use_nil
      ])
    )
  end

  get "/avatar/visitor/:id" do
    content =
      id
      |> Identicon.hash_input()
      |> Identicon.pick_color()
      |> Identicon.build_grid()
      |> Identicon.filter_odd_squares()
      |> Identicon.build_pixel_map()
      |> Identicon.draw_image()

    conn
    |> put_resp_header("Content-Type", "image/png")
    |> send_resp(
      200,
      content
    )
  end

  forward("/user", to: JollaCNAPI.Router.User)
  forward("/post", to: JollaCNAPI.Router.Post)
  forward("/tie", to: JollaCNAPI.Router.Tie)
  forward("/author", to: JollaCNAPI.Router.Author)
  forward("/feed", to: JollaCNAPI.Router.RSS)
  forward("/sitemap", to: JollaCNAPI.Router.Sitemap)

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
