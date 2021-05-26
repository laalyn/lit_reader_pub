defmodule LitReader.Paragraphs.Paragraph do
  use Ecto.Schema
  import Ecto.Changeset

  alias LitReader.Interactions.Interaction

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "paragraphs" do
    field :idx, :integer # shared with controls
    belongs_to :interaction, Interaction
  end
end
