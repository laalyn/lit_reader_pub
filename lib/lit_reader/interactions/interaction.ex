defmodule LitReader.Interactions.Interaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias LitReader.Characters.Character
  alias LitReader.Scenes.Scene

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "interactions" do
    field :idx, :integer
    belongs_to :character, Character
    belongs_to :scene, Scene
  end
end
