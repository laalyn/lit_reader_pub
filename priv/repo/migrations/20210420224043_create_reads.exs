defmodule LitReader.Repo.Migrations.CreateReads do
  use Ecto.Migration

  def change do
    create table(:reads, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :name, :string
      add :user_id, references(:users, [type: :binary_id, on_delete: :delete_all])

      timestamps()
    end

    create table(:sources, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :value, :text
      add :read_id, references(:reads, [type: :binary_id, on_delete: :delete_all])

      timestamps()
    end

    create table(:configs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :idx, :integer
      add :match_type, :string
      add :match_value, :string
      add :read_id, references(:reads, [type: :binary_id, on_delete: :delete_all])
    end

    # just so stuff doesn't become nasty soon
    # not by user input though, so not adding validation to changeset
    create unique_index(:sources, [:read_id])
    # regular stuff
    create index(:reads, [:user_id])
    create index(:configs, [:read_id])
  end
end
