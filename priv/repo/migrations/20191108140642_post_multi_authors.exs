defmodule JollaCNAPI.DB.Repo.Migrations.PostMultiAuthors do
  use Ecto.Migration

  def up do
    alter table("post") do
      add(:source_authors, {:array, :string}, null: true, comment: "原作者(可多个)")
    end

    execute("UPDATE post SET source_authors=(CASE
      WHEN source_author IS NULL THEN
        ARRAY[]::TEXT[]
      ELSE
        ARRAY[source_author]
    END)")

    execute("ALTER TABLE post ALTER COLUMN source_authors SET NOT NULL;")

    alter table("post") do
      remove(:source_author)
    end
  end

  def down do
    alter table("post") do
      add(:source_author, :string, null: true, comment: "原文作者")
    end

    execute("UPDATE post SET source_author=source_authors[0]")

    alter table("post") do
      remove(:source_authors)
    end
  end
end
