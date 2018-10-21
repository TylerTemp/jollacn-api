defmodule JollaCNAPI.Router.Post do
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
    conn = fetch_query_params(conn)
    params = conn.query_params

    offset = params |> Map.get("offset", "0") |> String.to_integer()
    passed_limit = params |> Map.get("limit", "50") |> String.to_integer()
    limit = Enum.min([passed_limit, 50])

    sql = "
      SELECT
        slug,
        title,
        author,
        cover,
        description,
        -- headerimg,
        -- content_md,
        -- content,
        to_char(inserted_at, 'YYYY-MM-DD HH24:MI:SS') AS inserted_at,
        to_char(updated_at, 'YYYY-MM-DD HH24:MI:SS') AS updated_at
      FROM post
      WHERE visiable = TRUE
      LIMIT $1
      OFFSET $2
    "
    args = [limit, offset]

    post_list =
      JollaCNAPI.DB.Repo
      |> Ecto.Adapters.SQL.query!(sql, args)
      |> JollaCNAPI.DB.Util.all()

    count_sql = "
      SELECT
        COUNT(1) AS count
      FROM post
      WHERE visiable = TRUE
      LIMIT $1
      OFFSET $2
    "
    count_args = [limit, offset]

    %{"count" => count} =
      JollaCNAPI.DB.Repo
      |> Ecto.Adapters.SQL.query!(count_sql, count_args)
      |> JollaCNAPI.DB.Util.one()

    result = %{
      "total" => count,
      "limit" => limit,
      "post_infos" => post_list
    }

    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(
      200,
      :jiffy.encode(result, [
        :use_nil
      ])
    )
  end

  post "/" do
    {:ok, body, conn} = read_body(conn)
    args = :jiffy.decode(body, [:return_maps, :use_nil])

    {status, post_result} =
      %JollaCNAPI.DB.Model.Post{}
      |> JollaCNAPI.DB.Model.Post.changeset(args)
      |> JollaCNAPI.DB.Repo.insert()

    if status == :error do
      error_msg =
        case post_result do
          %{errors: errors} ->
            errors
            |> Enum.map(fn
              {field, {msg, [type: expect_type, validation: :cast]}} ->
                "#{field}(#{expect_type}): failed on check #{msg}"

              {field, {_msg, [constraint: :unique, constraint_name: _]}} ->
                "#{field}(unique): exists"

              {field, {msg, [validation: validation_type]}} ->
                "#{field}(#{validation_type}): #{msg}"
            end)
            |> Enum.join("\n")

          _ ->
            inspect(post_result)
        end

      conn
      |> put_resp_header("Content-Type", "application/json")
      |> send_resp(
        500,
        :jiffy.encode(%{"message" => error_msg}, [
          :use_nil
        ])
      )
    else
      conn
      |> put_resp_header("Content-Type", "application/json")
      |> send_resp(
        200,
        :jiffy.encode(
          Map.drop(post_result, [:__struct__, :__meta__, :inserted_at, :updated_at]),
          [
            :use_nil
          ]
        )
      )
    end
  end

  get "/:slug" do
    sql = "
      SELECT
        slug,
        title,
        author,
        cover,
        description,
        headerimg,
        content_md,
        content,
        to_char(inserted_at, 'YYYY-MM-DD HH24:MI:SS') AS inserted_at,
        to_char(updated_at, 'YYYY-MM-DD HH24:MI:SS') AS updated_at
      FROM post
      WHERE slug = $1
    "
    args = [slug]

    post =
      JollaCNAPI.DB.Repo
      |> Ecto.Adapters.SQL.query!(sql, args)
      |> JollaCNAPI.DB.Util.one()

    if post == nil do
      conn
      |> put_resp_header("Content-Type", "application/json")
      |> send_resp(
        400,
        :jiffy.encode(%{"message" => "post #{slug} not found"}, [
          :use_nil
        ])
      )
    else
      conn
      |> put_resp_header("Content-Type", "application/json")
      |> send_resp(
        200,
        :jiffy.encode(post, [
          :use_nil
        ])
      )
    end

  end

  patch "/:slug" do
    {:ok, body, conn} = read_body(conn)
    args = :jiffy.decode(body, [:return_maps, :use_nil])

    case JollaCNAPI.DB.Repo.get(JollaCNAPI.DB.Model.Post, slug) do
      nil ->
        conn
        |> put_resp_header("Content-Type", "application/json")
        |> send_resp(
          500,
          :jiffy.encode(%{"message" => "post #{slug} not found"}, [
            :use_nil
          ])
        )
      old_post ->
        {status, post_result} = old_post
          |> JollaCNAPI.DB.Model.Post.changeset(args)
          |> JollaCNAPI.DB.Repo.update()
        if status == :error do
          error_msg =
            case post_result do
              %{errors: errors} ->
                errors
                |> Enum.map(fn
                  {field, {msg, [type: expect_type, validation: :cast]}} ->
                    "#{field}(#{expect_type}): failed on check #{msg}"

                  {field, {_msg, [constraint: :unique, constraint_name: _]}} ->
                    "#{field}(unique): exists"

                  {field, {msg, [validation: validation_type]}} ->
                    "#{field}(#{validation_type}): #{msg}"
                end)
                |> Enum.join("\n")

              _ ->
                inspect(post_result)
            end

          conn
          |> put_resp_header("Content-Type", "application/json")
          |> send_resp(
            500,
            :jiffy.encode(%{"message" => error_msg}, [
              :use_nil
            ])
          )
        else
          conn
          |> put_resp_header("Content-Type", "application/json")
          |> send_resp(
            200,
            :jiffy.encode(
              Map.drop(post_result, [:__struct__, :__meta__, :inserted_at, :updated_at]),
              [
                :use_nil
              ]
            )
          )
        end
    end
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
