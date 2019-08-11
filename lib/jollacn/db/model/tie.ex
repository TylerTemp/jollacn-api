defmodule JollaCNAPI.DB.Model.Tie do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tie" do
    field(:author, :string, null: false, comment: "创建者")
    field(:content_md, :string, null: false, comment: "内容(Markdown)")
    field(:content, :string, null: false, comment: "内容(Html)")

    field(:title, :string, null: true, comment: "标题")

    field(
      :media_previews,
      JollaCNAPI.DB.Util.Type.JSON,
      null: false,
      default: [],
      comment: "媒体预览"
    )

    field(:medias, JollaCNAPI.DB.Util.Type.JSON, null: false, default: [], comment: "媒体")

    field(:visiable, :boolean, null: false, default: true, comment: "可见")

    field(:inserted_at, :naive_datetime, null: false)
    field(:updated_at, :naive_datetime, null: false)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :author,
      :content_md,
      :content,
      :title,
      :media_previews,
      :medias,
      :visiable,
      :inserted_at,
      :updated_at
    ])
    |> JollaCNAPI.DB.Util.add_timestamps(struct)
    |> validate_required([
      :author,
      :content_md,
      :content,
      :media_previews,
      :medias,
      :visiable
      # :inserted_at,
      # :updated_at,
    ])
    |> unique_constraint(:title)
  end
end
