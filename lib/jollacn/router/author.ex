defmodule JollaCNAPI.Router.Author do
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
    sql = "
      SELECT *
      FROM author
      ORDER BY inserted_at DESC
    "
    args = []

    author_list =
      JollaCNAPI.DB.Repo
      |> Ecto.Adapters.SQL.query!(sql, args)
      |> JollaCNAPI.DB.Util.all(datetime: {"%F %T", :strftime})

    result = author_list

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

    {status, author_result} =
      %JollaCNAPI.DB.Model.Author{}
      |> JollaCNAPI.DB.Model.Author.changeset(args)
      |> JollaCNAPI.DB.Repo.insert()

    if status == :error do
      error_msg =
        case author_result do
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
            inspect(author_result)
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
          Map.drop(author_result, [:__struct__, :__meta__, :inserted_at, :updated_at]),
          [
            :use_nil
          ]
        )
      )
    end
  end

  get "/:name" do
    sql = "
      SELECT *
      FROM author
      WHERE name = $1
    "
    args = [name]

    author =
      JollaCNAPI.DB.Repo
      |> Ecto.Adapters.SQL.query!(sql, args)
      |> JollaCNAPI.DB.Util.one(datetime: {"%F %T", :strftime})

    if author == nil do
      conn
      |> put_resp_header("Content-Type", "application/json")
      |> send_resp(
        400,
        :jiffy.encode(%{"message" => "author #{name} not found"}, [
          :use_nil
        ])
      )
    else
      conn
      |> put_resp_header("Content-Type", "application/json")
      |> send_resp(
        200,
        :jiffy.encode(author, [
          :use_nil
        ])
      )
    end
  end

  patch "/:name" do
    {:ok, body, conn} = read_body(conn)
    args = :jiffy.decode(body, [:return_maps, :use_nil])

    case JollaCNAPI.DB.Repo.get(JollaCNAPI.DB.Model.Author, name) do
      nil ->
        conn
        |> put_resp_header("Content-Type", "application/json")
        |> send_resp(
          500,
          :jiffy.encode(%{"message" => "author #{name} not found"}, [
            :use_nil
          ])
        )

      old_author ->
        {status, author_result} =
          old_author
          |> JollaCNAPI.DB.Model.Author.changeset(args)
          |> JollaCNAPI.DB.Repo.update()

        if status == :error do
          error_msg =
            case author_result do
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
                inspect(author_result)
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
              Map.drop(author_result, [:__struct__, :__meta__, :inserted_at, :updated_at]),
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
