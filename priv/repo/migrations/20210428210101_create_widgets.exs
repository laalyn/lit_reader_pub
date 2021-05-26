defmodule LitReader.Repo.Migrations.CreateWidgets do
  use Ecto.Migration

  def change do
    create table(:widgets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      # add :idx, :integer not gonna bother for now, just sort by time
      add :name, :string
      # query stars here
      # action: list, item: word, granularity: read, match: 1
      add :action, :string # plot, plot over, plot multi, list, one, read
      add :item, :string # countable char, word
      add :granularity, :string # (time-frame)able if this is read,
      add :from_all, :boolean # skip through (`from all`)
      add :from_act_idx, :integer # autocomplete-able (client still requests idx)
      add :from_scene_idx, :integer
      add :from_interaction_idx, :integer
      add :from_paragraph_idx, :integer
      add :from_line_idx, :integer
      add :to_act_idx, :integer
      add :to_scene_idx, :integer
      add :to_interaction_idx, :integer
      add :to_paragraph_idx, :integer
      add :to_line_idx, :integer
      add :sort, :string # desc, asc
      # TODO actually implement matching
      add :match_i, :integer # matches literal value
      add :match_s, :string # matches literal value
      add :take, :integer # sql limit, 0 for all (or just nil)
      add :read_id, references(:reads, [type: :binary_id, on_delete: :delete_all])

      timestamps([type: :utc_datetime_usec])
    end

    create index(:widgets, [:read_id])
  end
end
