defmodule LitReader.Sources.Source do
  use Ecto.Schema
  import Ecto.Changeset

  alias LitReader.Reads.Read

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sources" do
    field :value, :string
    belongs_to :read, Read

    timestamps()
  end

  def changeset(source, attrs) do
    source
    |> cast(attrs, [:value], message: "invalid input")
    |> validate_required([:value], message: "some fields are missing")
  end
end
