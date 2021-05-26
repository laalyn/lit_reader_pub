defmodule LitReader.Repo.Migrations.CreateReadsFull do
  use Ecto.Migration

  def change do
    create table(:characters, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :read_id, references(:reads, [type: :binary_id, on_delete: :delete_all])
    end

    create table(:acts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :idx, :integer
      add :name, :string
      add :read_id, references(:reads, [type: :binary_id, on_delete: :delete_all])
    end

    create table(:scenes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :idx, :integer
      add :name, :string
      add :act_id, references(:acts, [type: :binary_id, on_delete: :delete_all])
    end

    create table(:interactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :idx, :integer
      add :character_id, references(:characters, [type: :binary_id, on_delete: :delete_all])
      add :scene_id, references(:scenes, [type: :binary_id, on_delete: :delete_all])
    end

    create table(:controls, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :idx, :integer # shared with paragraphs
      add :value, :text
      add :interaction_id, references(:interactions, [type: :binary_id, on_delete: :delete_all])
    end

    create table(:paragraphs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :idx, :integer # shared with controls
      add :interaction_id, references(:interactions, [type: :binary_id, on_delete: :delete_all])
    end

    create table(:lines, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :idx, :integer
      add :value, :text
      add :paragraph_id, references(:paragraphs, [type: :binary_id, on_delete: :delete_all])
    end

    create table(:words, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :value, :string
      add :cnt, :integer
      add :line_id, references(:lines, [type: :binary_id, on_delete: :delete_all])
    end

    create index(:characters, [:read_id])
    create index(:acts, [:read_id])
    create index(:scenes, [:act_id])
    create index(:interactions, [:character_id])
    create index(:interactions, [:scene_id])
    create index(:controls, [:interaction_id])
    create index(:paragraphs, [:interaction_id])
    create index(:lines, [:paragraph_id])
    create index(:words, [:line_id])
  end
end
