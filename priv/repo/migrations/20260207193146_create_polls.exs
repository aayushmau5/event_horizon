defmodule EventHorizon.Repo.Migrations.CreatePolls do
  use Ecto.Migration

  def change do
    create table(:polls) do
      add :slug, :string, null: false
      add :type, :string, null: false
      add :question, :string, null: false
      add :options, {:array, :string}, default: []
      add :blog_slug, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:polls, [:slug])
    create index(:polls, [:blog_slug])
  end
end
