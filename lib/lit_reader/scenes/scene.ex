defmodule LitReader.Scenes.Scene do
  use Ecto.Schema
  import Ecto.Changeset

  alias LitReader.Acts.Act

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "scenes" do
    field :idx, :integer
    field :name, :string
    belongs_to :act, Act
  end
end
