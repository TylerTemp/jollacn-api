defmodule JollaCNAPI.DB.Model.PostComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "post_comment" do
    field(:post_slug, :string, null: false, comment: "文章slug")
    field(:nickname, :string, null: false, comment: "评论昵称")
    field(:ip, :string, null: false, default: "", comment: "IP")
    field(:email, :string, null: false, default: "", comment: "email")
    field(:content_md, :string, null: false, comment: "内容(markdown)")
    field(:content, :string, null: false, comment: "内容(html)")

    field(:visiable, :boolean, null: false, default: true, comment: "可见")

    field(:inserted_at, :naive_datetime, null: false)
    field(:updated_at, :naive_datetime, null: false)
  end

  def changeset(struct, params \\ %{}) do
    cast_fields = [
      :post_slug,
      :nickname,
      :ip,
      :email,
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
      :post_slug,
      :nickname,
      :ip,
      :content_md,
      :content,
      :visiable
      # :inserted_at,
      # :updated_at,
    ])
  end
end
