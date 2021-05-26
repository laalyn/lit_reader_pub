defmodule LitReader.Lines.Line do
  use Ecto.Schema
  import Ecto.Changeset

  alias LitReader.Paragraphs.Paragraph

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "lines" do
    field :idx, :integer
    field :value, :string
    belongs_to :paragraph, Paragraph
  end
end
