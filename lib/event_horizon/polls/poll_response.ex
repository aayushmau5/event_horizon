defmodule EventHorizon.Polls.PollResponse do
  use Ecto.Schema
  import Ecto.Changeset

  schema "poll_responses" do
    field(:respondent_id, :string)
    field(:choice, :string)
    field(:body, :string)

    belongs_to(:poll, EventHorizon.Polls.Poll)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(response, attrs, poll) do
    response
    |> cast(attrs, [:respondent_id, :choice, :body])
    |> validate_required([:respondent_id])
    |> put_assoc(:poll, poll)
    |> validate_response(poll)
    |> unique_constraint([:poll_id, :respondent_id],
      message: "has already responded to this poll"
    )
  end

  defp validate_response(changeset, poll) do
    case poll.type do
      type when type in ["yes_no", "multiple_choice"] ->
        changeset
        |> validate_required([:choice], message: "must select an option")
        |> validate_inclusion(:choice, poll.options, message: "is not a valid option")

      "open_ended" ->
        changeset
        |> validate_required([:body], message: "must provide an answer")
        |> validate_length(:body, min: 1, max: 2000)

      _ ->
        changeset
    end
  end
end
