defmodule JollaCNAPI.DB.Model.Tie do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tie" do
    field(:author, :string)
    field(:content_md, :string)
    field(:content, :string)

    field(:title, :string, null: true)

    field(
      :media_previews,
      JollaCNAPI.DB.Util.Type.JSON,
      null: false,
      default: []
    )

    field(:medias, JollaCNAPI.DB.Util.Type.JSON, default: [])

    field(:visiable, :boolean, default: true)

    field(:inserted_at, :naive_datetime)
    field(:updated_at, :naive_datetime)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :author,
      :content_md,
      :content,
      :title,
      :media_previews,
      :medias,
      :visiable,
      :inserted_at,
      :updated_at
    ])
    |> JollaCNAPI.DB.Util.add_timestamps(struct)
    |> validate_required([
      :author,
      :content_md,
      :content,
      :media_previews,
      :medias,
      :visiable
      # :inserted_at,
      # :updated_at,
    ])
    |> unique_constraint(:title)
  end
end
