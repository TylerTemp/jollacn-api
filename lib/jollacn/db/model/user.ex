defmodule JollaCNAPI.DB.Model.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user" do
    field(:name, :string, null: false, comment: "昵称(唯一)")
    field(:password_encrypted, :string, null: false, comment: "加密密码")
    field(:permissions, {:array, :string}, null: false, default: [], comment: "权限")

    field(:inserted_at, :naive_datetime, null: false)
    field(:updated_at, :naive_datetime, null: false)
  end

  def changeset(struct, params \\ %{}) do
    cast_fields = [
      :name,
      :password_encrypted,
      :permissions,
      :inserted_at,
      :updated_at
    ]

    struct
    |> cast(params, cast_fields)
    |> JollaCNAPI.DB.Util.add_timestamps(struct)
    |> validate_required([
      :name,
      :permissions,
      :password_encrypted
      # :inserted_at,
      # :updated_at
    ])
    |> unique_constraint(:name)
  end
end
