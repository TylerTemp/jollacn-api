defmodule Mix.Tasks.LoadArticles do
  use Mix.Task

  def run([source_file]) do
    {:ok, _} = Application.ensure_all_started(:jollacn_api)

    content =
      source_file |> File.read!()
      |> String.replace("https://dn-jolla.qbox.me", "http://q-jolla.notexists.top")

    articles = :jiffy.decode(content, [:use_nil, :return_maps])
    # |> (fn([first | _]) -> [first] end).()
    articles
    |> Enum.filter(fn %{"slug" => slug} -> slug not in ["trans_what"] end)
    |> Enum.map(
      # "cover" => cover,
      fn %{
           "title" => title,
           "content" => content_md,
           "edit_time" => edit_time,
           "create_time" => create_time,
           "banner" => banner,
           "slug" => slug
         } = article ->
        description = Map.get(article, "description")
        cover = Map.get(article, "cover")
        content_html = markdown_to_html(content_md)
        inserted_at = get_time(create_time)
        updated_at = get_time(edit_time)

        args = %{
          "title" => title,
          "author" => "TylerTemp",
          "cover" => cover,
          "description" => description,
          "headerimg" => banner,
          "content_md" => content_md,
          "content" => content_html,
          "visiable" => true,
          "inserted_at" => inserted_at,
          "updated_at" => updated_at
          # "slug" => slug,
        }

        case JollaCNAPI.DB.Repo.get(JollaCNAPI.DB.Model.Post, slug) do
          nil -> %JollaCNAPI.DB.Model.Post{slug: slug}
          post -> post
        end
        |> JollaCNAPI.DB.Model.Post.changeset(args)
        |> JollaCNAPI.DB.Repo.insert_or_update!()
      end
    )
  end

  def get_time(time_second_float) do
    # IO.puts(time_second_float)
    timezone = Timex.Timezone.get("Asia/Shanghai", Timex.now())

    (time_second_float * 1_000_000)
    |> trunc()
    |> Timex.from_unix(:microseconds)
    |> Timex.Timezone.convert(timezone)
  end

  def markdown_to_html(md) do
    convert_python_file = Path.join([File.cwd!(), "tool", "md.py"])
    # IO.puts("running file #{convert_python_file}")
    {result, 0} = System.cmd("python", [convert_python_file, md])
    result
  end
end
