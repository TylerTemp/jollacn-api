defmodule JollaCNAPI.DB.Repo.Migrations.PostAllowSource do
  use Ecto.Migration

  def change do
    create table("author", primary_key: false) do
      add(:name, :string, primary_key: true, comment: "id名称")
      add(:display_name, :string, null: false, comment: "显示名")
      add(:avatar, :json, null: true, comment: "头像")
      add(:description, :string, null: true, comment: "描述")

      add(:inserted_at, :naive_datetime, null: false, default: fragment("now()"))
      add(:updated_at, :naive_datetime, null: false, default: fragment("now()"))
    end

    alter table("post") do
      add(:source_type, :string, null: true, comment: "null: 未知；translation：翻译；original: 原创")
      add(:source_url, :string, null: true, comment: "原文url")
      add(:source_title, :string, null: true, comment: "原文标题")
      add(:source_author, :string, null: true, comment: "原文作者")
      add(:tags, {:array, :string}, null: true, comment: "标签")
    end
  end

end
