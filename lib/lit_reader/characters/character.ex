defmodule LitReader.Characters.Character do
  use Ecto.Schema
  import Ecto.Changeset

  alias LitReader.Reads.Read

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "characters" do
    field :name, :string
    belongs_to :read, Read
  end
end
