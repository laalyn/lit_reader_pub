defmodule LitReader.Configs.Config do
  use Ecto.Schema
  import Ecto.Changeset

  alias LitReader.Reads.Read

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "configs" do
    field :type, :string
    field :idx, :integer
    field :match_type, :string
    field :match_value, :string
    belongs_to :read, Read
  end
end
