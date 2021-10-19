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
      ORDER BY inserted_at DESC
      OFFSET $2
      LIMIT $1
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
    "
    count_args = []

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
        tags,
        source_type,
        source_url,
        source_title,
        (CASE
          WHEN array_length(source_authors, 1) IS NULL THEN NULL
          ELSE source_authors[1]
        END) AS source_author,
        source_authors,
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
        {status, post_result} =
          old_post
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

  get "/:post_slug/comment" do
    conn = fetch_query_params(conn)
    params = conn.query_params

    offset = params |> Map.get("offset", "0") |> String.to_integer()
    passed_limit = params |> Map.get("limit", "50") |> String.to_integer()
    limit = Enum.min([passed_limit, 50])

    sql = "
      SELECT
        COUNT(*) OVER() AS total_count,
        id,
        post_slug,
        nickname,
        ip,
        email,
        content_md,
        content,
        -- visiable,
        to_char(inserted_at, 'YYYY-MM-DD HH24:MI:SS') AS inserted_at,
        to_char(updated_at, 'YYYY-MM-DD HH24:MI:SS') AS updated_at
      FROM post_comment
      WHERE visiable = TRUE
        AND post_slug = $1
      OFFSET $3
      LIMIT $2
    "
    args = [post_slug, limit, offset]

    post_comment_list =
      JollaCNAPI.DB.Repo
      |> Ecto.Adapters.SQL.query!(sql, args)
      |> JollaCNAPI.DB.Util.all()
      |> Enum.map(fn %{"ip" => ip, "email" => email} = tie_comment ->
        hash = :md5 |> :crypto.hash("#{ip}_#{email}") |> Base.encode16()
        avatar = "/avatar/visitor/#{hash}"

        tie_comment
        |> Map.merge(%{"avatar" => avatar})
        |> Map.drop(["ip", "email"])
      end)

    count =
      if length(post_comment_list) == 0 do
        0
      else
        [%{"total_count" => total_count} | _] = post_comment_list
        total_count
      end

    result = %{
      "total" => count,
      "limit" => limit,
      "comments" => post_comment_list
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

  post "/:slug/comment" do
    {:ok, body, conn} = read_body(conn)
    user_ip = JollaCNAPI.Router.Util.get_ip(conn)

    # TODO: markdown transfer
    args =
      body
      |> :jiffy.decode([:return_maps, :use_nil])
      |> (fn %{"content" => content} = input_args ->
            Map.merge(input_args, %{"post_slug" => slug, "ip" => user_ip, "content_md" => content})
          end).()

    {status, comment_result} =
      %JollaCNAPI.DB.Model.PostComment{}
      |> JollaCNAPI.DB.Model.PostComment.changeset(args)
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
      ip = user_ip
      email = Map.get(args, nil)
      hash = :md5 |> :crypto.hash("#{ip}_#{email}") |> Base.encode16()
      avatar = "/avatar/visitor/#{hash}"

      result =
        comment_result
        |> Map.drop([:__struct__, :__meta__, :inserted_at, :updated_at])
        |> Map.merge(%{avatar: avatar})

      conn
      |> put_resp_header("Content-Type", "application/json")
      |> send_resp(
        200,
        :jiffy.encode(result, [
          :use_nil
        ])
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
