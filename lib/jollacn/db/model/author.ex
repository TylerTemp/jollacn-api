defmodule JollaCNAPI.DB.Model.Author do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:name, :string, []}
  schema "author" do
    field(:display_name, :string, null: false, comment: "显示名")
    field(:avatar, JollaCNAPI.DB.Util.Type.JSON, null: true, comment: "头像{}, default: 默认")
    field(:description, :string, null: true, comment: "描述")

    field(:inserted_at, :naive_datetime, null: false)
    field(:updated_at, :naive_datetime, null: false)
  end

  def changeset(struct, params \\ %{}) do
    cast_fields = [
      :name,
      :display_name,
      :avatar,
      :description,
      :inserted_at,
      :updated_at
    ]

    struct
    |> cast(params, cast_fields)
    |> JollaCNAPI.DB.Util.add_timestamps(struct)
    |> validate_required([
      :name,
      :display_name,
      :inserted_at,
      :updated_at
    ])
    |> unique_constraint(:name, name: :author_pkey)
  end
end
