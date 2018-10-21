defmodule JollaCNAPI.Router.Tie do
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
        id,
        author,
        content_md,
        content,
        media_previews,
        medias,
        to_char(inserted_at, 'YYYY-MM-DD HH24:MI:SS') AS inserted_at,
        to_char(updated_at, 'YYYY-MM-DD HH24:MI:SS') AS updated_at
      FROM tie
      WHERE visiable = TRUE
      LIMIT $1
      OFFSET $2
    "
    args = [limit, offset]

    tie_list =
      JollaCNAPI.DB.Repo
      |> Ecto.Adapters.SQL.query!(sql, args)
      |> JollaCNAPI.DB.Util.all()

    count_sql = "
      SELECT
        COUNT(1) AS count
      FROM tie
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
      "ties" => tie_list
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

    {status, tie_result} =
      %JollaCNAPI.DB.Model.Tie{}
      |> JollaCNAPI.DB.Model.Tie.changeset(args)
      |> JollaCNAPI.DB.Repo.insert()

    if status == :error do
      error_msg =
        case tie_result do
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
            inspect(tie_result)
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
          Map.drop(tie_result, [:__struct__, :__meta__, :inserted_at, :updated_at]),
          [
            :use_nil
          ]
        )
      )
    end
  end

  get "/:tie_id_str" do
    tie_id = String.to_integer(tie_id_str)
    sql = "
      SELECT
        id,
        author,
        content_md,
        content,
        media_previews,
        medias,
        to_char(inserted_at, 'YYYY-MM-DD HH24:MI:SS') AS inserted_at,
        to_char(updated_at, 'YYYY-MM-DD HH24:MI:SS') AS updated_at
      FROM tie
      WHERE id = $1
    "
    args = [tie_id]

    tie =
      JollaCNAPI.DB.Repo
      |> Ecto.Adapters.SQL.query!(sql, args)
      |> JollaCNAPI.DB.Util.one()

    if tie == nil do
      conn
      |> put_resp_header("Content-Type", "application/json")
      |> send_resp(
        400,
        :jiffy.encode(%{"message" => "tie #{tie_id} not found"}, [
          :use_nil
        ])
      )
    else
      conn
      |> put_resp_header("Content-Type", "application/json")
      |> send_resp(
        200,
        :jiffy.encode(tie, [
          :use_nil
        ])
      )
    end
  end

  patch "/:tie_id_str" do
    tie_id = String.to_integer(tie_id_str)
    {:ok, body, conn} = read_body(conn)
    args = :jiffy.decode(body, [:return_maps, :use_nil])

    case JollaCNAPI.DB.Repo.get(JollaCNAPI.DB.Model.Tie, tie_id) do
      nil ->
        conn
        |> put_resp_header("Content-Type", "application/json")
        |> send_resp(
          500,
          :jiffy.encode(%{"message" => "tie #{tie_id} not found"}, [
            :use_nil
          ])
        )

      old_tie ->
        {status, tie_result} =
          old_tie
          |> JollaCNAPI.DB.Model.Tie.changeset(args)
          |> JollaCNAPI.DB.Repo.update()

        if status == :error do
          error_msg =
            case tie_result do
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
                inspect(tie_result)
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
              Map.drop(tie_result, [:__struct__, :__meta__, :inserted_at, :updated_at]),
              [
                :use_nil
              ]
            )
          )
        end
    end
  end

  get "/:tie_id_str/comment" do
    tie_id = String.to_integer(tie_id_str)
    conn = fetch_query_params(conn)
    params = conn.query_params

    offset = params |> Map.get("offset", "0") |> String.to_integer()
    passed_limit = params |> Map.get("limit", "50") |> String.to_integer()
    limit = Enum.min([passed_limit, 50])

    sql = "
      SELECT
        tie_id,
        nickname,
        -- ip,
        -- email,
        content_md,
        content,
        -- visiable,
        to_char(inserted_at, 'YYYY-MM-DD HH24:MI:SS') AS inserted_at,
        to_char(updated_at, 'YYYY-MM-DD HH24:MI:SS') AS updated_at
      FROM tie_comment
      WHERE visiable = TRUE
        AND tie_id = $1
      LIMIT $2
      OFFSET $3
    "
    args = [tie_id, limit, offset]

    tie_comment_list =
      JollaCNAPI.DB.Repo
      |> Ecto.Adapters.SQL.query!(sql, args)
      |> JollaCNAPI.DB.Util.all()

    count_sql = "
      SELECT
        COUNT(1) AS count
      FROM tie_comment
      WHERE visiable = TRUE
        AND tie_id = $1
      LIMIT $2
      OFFSET $3
    "
    count_args = [tie_id, limit, offset]

    %{"count" => count} =
      JollaCNAPI.DB.Repo
      |> Ecto.Adapters.SQL.query!(count_sql, count_args)
      |> JollaCNAPI.DB.Util.one()

    result = %{
      "total" => count,
      "limit" => limit,
      "comments" => tie_comment_list
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

  post "/:tie_id_str/comment" do
    tie_id = String.to_integer(tie_id_str)
    {:ok, body, conn} = read_body(conn)
    user_ip = JollaCNAPI.Router.Util.get_ip(conn)

    # TODO: markdown transfer
    args =
      body
      |> :jiffy.decode([:return_maps, :use_nil])
      |> (fn %{"content" => content} = input_args ->
            Map.merge(input_args, %{"tie_id" => tie_id, "ip" => user_ip, "content_md" => content})
          end).()

    {status, comment_result} =
      %JollaCNAPI.DB.Model.TieComment{}
      |> JollaCNAPI.DB.Model.TieComment.changeset(args)
      |> JollaCNAPI.DB.Repo.insert()

    if status == :error do
      error_msg =
        case comment_result do
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
            inspect(comment_result)
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
          Map.drop(comment_result, [:__struct__, :__meta__, :inserted_at, :updated_at]),
          [
            :use_nil
          ]
        )
      )
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
