defmodule JollaCNAPI.DB.Repo.Migrations.TieTitle do
  use Ecto.Migration

  def change do
    alter table("tie") do
      add(:title, :string, null: true, comment: "标题")
    end

    create(index("tie", [:title], unique: true, comment: "Index Comment"))
  end
end
