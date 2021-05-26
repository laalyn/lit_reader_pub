defmodule LitReader.Words.Word do
  use Ecto.Schema
  import Ecto.Changeset

  alias LitReader.Lines.Line

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "words" do
    field :value, :string
    field :cnt, :integer
    belongs_to :line, Line
  end
end
