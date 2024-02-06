defmodule JollaCNAPI.DB.Model.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user" do
    field(:name, :string)
    field(:password_encrypted, :string)
    field(:permissions, {:array, :string}, default: [])

    field(:inserted_at, :naive_datetime)
    field(:updated_at, :naive_datetime)
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
