defmodule JollaCNAPI.DB.Model.Author do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:name, :string, []}
  schema "author" do
    field(:display_name, :string)
    field(:avatar, JollaCNAPI.DB.Util.Type.JSON, default: [])
    field(:description, :string)

    field(:inserted_at, :naive_datetime)
    field(:updated_at, :naive_datetime)
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
