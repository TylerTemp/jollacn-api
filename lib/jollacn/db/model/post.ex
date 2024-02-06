defmodule JollaCNAPI.DB.Model.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:slug, :string, []}
  schema "post" do
    field(:title, :string)
    field(:author, :string)
    field(:cover, :string)
    field(:description, :string)
    field(:headerimg, :string)
    field(:content_md, :string)
    field(:content, :string)
    field(:tags, {:array, :string})

    field(:source_type, :string)
    field(:source_url, :string)
    field(:source_title, :string)
    # field(:source_author, :string, comment: "原文作者")
    field(:source_authors, {:array, :string}, default: [])

    field(:visiable, :boolean, default: true)

    field(:inserted_at, :naive_datetime)
    field(:updated_at, :naive_datetime)
  end

  def changeset(struct, params \\ %{}) do
    cast_fields = [
      :slug,
      :title,
      :author,
      :cover,
      :description,
      :headerimg,
      :content_md,
      :content,
      :tags,
      :source_type,
      :source_url,
      :source_title,
      # :source_author,
      :source_authors,
      :visiable,
      :inserted_at,
      :updated_at
    ]

    struct
    |> cast(params, cast_fields)
    |> JollaCNAPI.DB.Util.add_timestamps(struct)
    |> validate_required([
      :slug,
      :title,
      :author,
      :content_md,
      :content,
      :source_authors,
      :visiable,
      :inserted_at,
      :updated_at
    ])
    |> unique_constraint(:slug, name: :post_pkey)
  end
end
