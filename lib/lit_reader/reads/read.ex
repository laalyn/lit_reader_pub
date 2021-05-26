defmodule LitReader.Reads.Read do
  use Ecto.Schema
  import Ecto.Changeset

  alias LitReader.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "reads" do
    field :type, :string
    field :name, :string
    belongs_to :user, User

    timestamps()
  end

  def changeset(read, attrs) do
    read
    |> cast(attrs, [:type, :name], message: "invalid input")
    |> validate_required([:type, :name], message: "some fields are missing")
  end
end
