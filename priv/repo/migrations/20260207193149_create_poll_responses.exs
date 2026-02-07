defmodule EventHorizon.Repo.Migrations.CreatePollResponses do
  use Ecto.Migration

  def change do
    create table(:poll_responses) do
      add :poll_id, references(:polls, on_delete: :delete_all), null: false
      add :respondent_id, :string, null: false
      add :choice, :string
      add :body, :text

      timestamps(type: :utc_datetime)
    end

    create index(:poll_responses, [:poll_id])
    create unique_index(:poll_responses, [:poll_id, :respondent_id])
    create index(:poll_responses, [:respondent_id])
  end
end
