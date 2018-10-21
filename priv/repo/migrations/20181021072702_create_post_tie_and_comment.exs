defmodule JollaCNAPI.DB.Repo.Migrations.CreatePostTieAndComment do
  use Ecto.Migration

  def change do
    create table(:"post", primary_key: false) do
      add(:slug, :string, primary_key: true, comment: "slug")
      add(:title, :string, null: false, comment: "标题")
      add(:author, :string, null: false, comment: "创建者")
      add(:cover, :string, null: true, comment: "封面")
      add(:description, :text, null: true, comment: "描述")
      add(:headerimg, :string, null: true, comment: "顶部图像")
      add(:content_md, :text, null: false, comment: "内容(Markdown)")
      add(:content, :text, null: false, comment: "内容(Html)")

      add(:visiable, :boolean, null: false, default: :true, comment: "可见")

      add(:inserted_at, :naive_datetime, null: false, default: fragment("now()"))
      add(:updated_at, :naive_datetime, null: false, default: fragment("now()"))
    end

    create table(:"post_comment") do
      add(:post_slug, :string, null: false, comment: "文章slug")
      add(:nickname, :string, null: false, comment: "评论昵称")
      add(:ip, :string, null: false, comment: "IP")
      add(:email, :string, null: true, comment: "email")
      add(:content_md, :text, null: false, comment: "内容(markdown)")
      add(:content, :text, null: false, comment: "内容(html)")

      add(:visiable, :boolean, null: false, default: :true, comment: "可见")

      add(:inserted_at, :naive_datetime, null: false, default: fragment("now()"))
      add(:updated_at, :naive_datetime, null: false, default: fragment("now()"))
    end

    create table(:"tie") do
      add(:author, :string, null: false, comment: "创建者")
      add(:content_md, :text, null: false, comment: "内容(Markdown)")
      add(:content, :text, null: false, comment: "内容(Html)")
      add(:media_previews, :json, null: false, default: "[]", comment: "媒体预览")
      add(:medias, :json, null: false, default: "[]", comment: "媒体")

      add(:visiable, :boolean, null: false, default: :true, comment: "可见")

      add(:inserted_at, :naive_datetime, null: false, default: fragment("now()"))
      add(:updated_at, :naive_datetime, null: false, default: fragment("now()"))
    end

    create table(:"tie_comment") do
      add(:tie_id, :integer, null: false, comment: "tie id")
      add(:nickname, :string, null: false, comment: "评论昵称")
      add(:ip, :string, null: false, comment: "IP")
      add(:email, :string, null: true, comment: "email")
      add(:content_md, :text, null: false, comment: "内容(markdown)")
      add(:content, :text, null: false, comment: "内容(html)")

      add(:visiable, :boolean, null: false, default: :true, comment: "可见")

      add(:inserted_at, :naive_datetime, null: false, default: fragment("now()"))
      add(:updated_at, :naive_datetime, null: false, default: fragment("now()"))
    end
  end

end
