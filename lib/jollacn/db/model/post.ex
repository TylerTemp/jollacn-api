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
      :visiable
      # :inserted_at,
      # :updated_at,
    ])
    |> unique_constraint(:slug, name: :post_pkey)
  end
end
