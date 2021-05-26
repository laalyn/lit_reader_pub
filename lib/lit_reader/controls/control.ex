defmodule LitReader.Controls.Control do
  use Ecto.Schema
  import Ecto.Changeset

  alias LitReader.Interactions.Interaction

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "controls" do
    field :idx, :integer # shared with paragraphs
    field :value, :string
    belongs_to :interaction, Interaction
  end
end
