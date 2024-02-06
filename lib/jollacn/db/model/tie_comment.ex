defmodule JollaCNAPI.DB.Model.TieComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tie_comment" do
    field(:tie_id, :integer)
    field(:nickname, :string)
    field(:ip, :string)
    field(:email, :string)
    field(:content_md, :string)
    field(:content, :string)

    field(:visiable, :boolean, default: true)

    field(:inserted_at, :naive_datetime)
    field(:updated_at, :naive_datetime)
  end

  def changeset(struct, params \\ %{}) do
    cast_fields = [
      :tie_id,
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
      :tie_id,
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
