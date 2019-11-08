defmodule JollaCNAPI.DB.Model.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:slug, :string, []}
  schema "post" do
    field(:title, :string, null: false, comment: "标题")
    field(:author, :string, null: false, comment: "创建者")
    field(:cover, :string, null: true, comment: "封面")
    field(:description, :string, null: true, comment: "描述")
    field(:headerimg, :string, null: true, comment: "顶部图像")
    field(:content_md, :string, null: false, comment: "内容(Markdown)")
    field(:content, :string, null: false, comment: "内容(Html)")
    field(:tags, {:array, :string}, null: true, comment: "标签")

    field(:source_type, :string, null: true, comment: "null: 未知；translation：翻译；original: 原创")
    field(:source_url, :string, null: true, comment: "原文url")
    field(:source_title, :string, null: true, comment: "原文标题")
    # field(:source_author, :string, null: true, comment: "原文作者")
    field(:source_authors, {:array, :string}, null: false, default: [], comment: "原文作者")

    field(:visiable, :boolean, null: false, default: true, comment: "可见")

    field(:inserted_at, :naive_datetime, null: false)
    field(:updated_at, :naive_datetime, null: false)
  end

  def changeset(struct, params \\ %{}) do
    cast_fields = [
      :slug,
      :title,
      :author,
      :cover,
      :description,
      :headerimg,
      :content_md,
      :content,
      :tags,
      :source_type,
      :source_url,
      :source_title,
      # :source_author,
      :source_authors,
      :visiable,
      :inserted_at,
      :updated_at
    ]

    struct
    |> cast(params, cast_fields)
    |> JollaCNAPI.DB.Util.add_timestamps(struct)
    |> validate_required([
      :slug,
      :title,
      :author,
      :content_md,
      :content,
      :source_authors,
      :visiable,
      :inserted_at,
      :updated_at
    ])
    |> unique_constraint(:slug, name: :post_pkey)
  end
end
