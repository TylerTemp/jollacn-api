defmodule JollaCNAPI.Router.RSS do
  use Plug.Router
  # use Plug.ErrorHandler
  # require Logger

  plug(Plug.Logger, log: :debug)
  # plug(Plug.Parsers.JSON)
  # plug Plug.Parsers,
  #   parsers: [:urlencoded, :json],
  #   pass: ["text/*"],
  #   json_decoder: Poison
  # plug(Plug.MethodOverride)
  plug(:match)
  plug(:dispatch)

  @rss_template_path Path.join([File.cwd!(), "lib", "jollacn", "template", "rss.xml"])

  get "/" do
    # IO.inspect(conn)

    host = get_host(conn)
    protocol = get_protocol(conn)

    tie_sql = "
      SELECT
        id,
        author,
        -- content_md,
        content,
        media_previews,
        -- medias,
        inserted_at,
        updated_at
      FROM tie
      WHERE visiable = TRUE
      ORDER BY inserted_at DESC
      OFFSET 0
      LIMIT 10
    "
    tie_args = []

    tie_list =
      JollaCNAPI.DB.Repo
      |> Ecto.Adapters.SQL.query!(tie_sql, tie_args)
      |> JollaCNAPI.DB.Util.all()
      |> Enum.map(fn %{
                       "id" => id,
                       "author" => author,
                       "content" => content,
                       "media_previews" => media_previews,
                       "inserted_at" => inserted_at
                     } ->
        # time_to_pub_date(inserted_at)
        %{
          "slug" => "/tie/#{id}",
          "title" => escape_html("快讯(#{id})"),
          "author" => escape_html(author),
          "pub_date" => time_to_pub_date(inserted_at),
          # "pub_date" => "pub_date",
          "inserted_at" => inserted_at,
          "medias" => Enum.map(media_previews, fn %{"src" => src} -> src end),
          "content" => escape_html(content)
        }
      end)

    post_sql = "
      SELECT
        slug,
        title,
        author,
        -- cover,
        description,
        headerimg,
        -- content_md,
        content,
        inserted_at,
        updated_at
      FROM post
      WHERE visiable = TRUE
      ORDER BY inserted_at DESC
      OFFSET 0
      LIMIT 3
    "
    post_args = []

    post_list =
      JollaCNAPI.DB.Repo
      |> Ecto.Adapters.SQL.query!(post_sql, post_args)
      |> JollaCNAPI.DB.Util.all()
      |> Enum.map(fn %{
                       "slug" => slug,
                       "title" => title,
                       "author" => author,
                       "content" => content,
                       "headerimg" => headerimg,
                       "inserted_at" => inserted_at
                     } ->
        # time_to_pub_date(inserted_at)
        %{
          "slug" => "/post/#{slug}",
          "title" => escape_html(title),
          "author" => escape_html(author),
          "pub_date" => time_to_pub_date(inserted_at),
          # "pub_date" => "pub_date",
          "inserted_at" => inserted_at,
          "medias" =>
            if headerimg do
              [headerimg]
            else
              []
            end,
          "content" => escape_html(content)
        }
      end)

    articles =
      Enum.sort_by(
        tie_list ++ post_list,
        fn %{"inserted_at" => inserted_at} -> inserted_at end,
        &(NaiveDateTime.compare(&1, &2) == :gt)
      )

    # Enum.each(articles, fn(%{"inserted_at" => inserted_at}) ->
    #   IO.inspect(inserted_at)
    # end)

    content =
      EEx.eval_file(
        @rss_template_path,
        protocol: protocol,
        host: host,
        this_year: DateTime.utc_now().year,
        articles: articles
      )

    conn
    |> put_resp_header("Content-Type", "application/rss+xml; charset=\"utf-8\"")
    |> send_resp(
      200,
      content
    )
  end

  def get_host(%{host: host}) when host in ["notexists.top", "jolla.comes.today", "jolla.cn"] do
    host
  end

  def get_host(_) do
    "notexists.top"
  end

  def get_protocol(%{scheme: scheme, req_headers: req_headers}) do
    headers = Map.new(req_headers)

    case headers do
      %{"x-scheme" => x_scheme} ->
        x_scheme

      _ ->
        "#{scheme}"
    end
  end

  def time_to_pub_date(time) do
    # IO.puts("time")
    # IO.inspect(time)
    # |> DateTime.from_naive!("Asia/Shanghai")
    time
    |> Timex.to_datetime("Asia/Shanghai")
    |> Calendar.DateTime.Format.rfc2822()

    # IO.puts("result")
    # IO.inspect(result)
  end

  def escape_html(html) do
    # html
    # |> HtmlEntities.encode()
    # |> (fn(content) -> String.replace(content, "=", "&#61;") end).()
    HtmlEntities.encode(html)
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

  # def handle_errors(conn, %{kind: _kind, reason: reason, stack: stack}) do
  #   Logger.error("SERVERERROR: #{inspect(reason)} : #{inspect(stack)}")
  #
  #   conn
  #   |> put_resp_header("Content-Type", "application/json")
  #   |> send_resp(500, :jiffy.encode(%{"message" => "server error"}, [:use_nil]))
  # end
end
