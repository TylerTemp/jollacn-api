defmodule JollaCNAPI.DB.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:user) do
      add(:name, :string, null: false, comment: "昵称(唯一)")
      add(:password_encrypted, :text, null: false, comment: "加密密码")
      add(:permissions, {:array, :string}, null: false, default: [], comment: "权限")

      add(:inserted_at, :naive_datetime, null: false, default: fragment("now()"))
      add(:updated_at, :naive_datetime, null: false, default: fragment("now()"))
    end

    create(index(:user, [:name], unique: true))
  end
end
