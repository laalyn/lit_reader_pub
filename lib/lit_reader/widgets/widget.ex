defmodule LitReader.Widgets.Widget do
  use Ecto.Schema
  import Ecto.Changeset

  alias LitReader.Reads.Read

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]
  schema "widgets" do
    field :name, :string
    field :action, :string
    field :item, :string
    field :granularity, :string
    field :from_all, :boolean
    field :from_act_idx, :integer
    field :from_scene_idx, :integer
    field :from_interaction_idx, :integer
    field :from_paragraph_idx, :integer
    field :from_line_idx, :integer
    field :to_act_idx, :integer
    field :to_scene_idx, :integer
    field :to_interaction_idx, :integer
    field :to_paragraph_idx, :integer
    field :to_line_idx, :integer
    field :sort, :string # desc, asc
    # literal value matches, i'm lazy
    field :match_i, :integer
    field :match_s, :string
    field :take, :integer # sql limit, 0 for all
    belongs_to :read, Read

    timestamps()
  end

  def changeset(source, attrs) do
    source
    |> cast(attrs, [:name, :action, :item, :granularity, :from_all, :from_act_idx, :from_scene_idx, :from_interaction_idx, :from_paragraph_idx, :from_line_idx, :to_act_idx, :to_scene_idx, :to_interaction_idx, :to_paragraph_idx, :to_line_idx, :sort, :match_i, :match_s, :take, :read_id], message: "invalid input")
    |> validate_required([:action, :item, :from_all, :read_id], message: "some fields are missing")
  end
end
