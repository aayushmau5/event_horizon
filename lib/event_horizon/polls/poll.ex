defmodule EventHorizon.Polls.Poll do
  use Ecto.Schema
  import Ecto.Changeset

  @types ~w(yes_no multiple_choice open_ended)

  schema "polls" do
    field :slug, :string
    field :type, :string
    field :question, :string
    field :options, {:array, :string}, default: []
    field :blog_slug, :string

    has_many :responses, EventHorizon.Polls.PollResponse

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(poll, attrs) do
    poll
    |> cast(attrs, [:slug, :type, :question, :options, :blog_slug])
    |> validate_required([:slug, :type, :question, :blog_slug])
    |> validate_inclusion(:type, @types)
    |> validate_format(:slug, ~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/,
      message: "must be lowercase alphanumeric with hyphens"
    )
    |> unique_constraint(:slug)
    |> validate_options()
  end

  defp validate_options(changeset) do
    type = get_field(changeset, :type)
    options = get_field(changeset, :options) || []

    case type do
      "yes_no" ->
        # yes_no polls always use ["Yes", "No"], override whatever was passed
        put_change(changeset, :options, ["Yes", "No"])

      "multiple_choice" ->
        if length(options) < 2 do
          add_error(changeset, :options, "must have at least 2 options for multiple choice")
        else
          changeset
        end

      "open_ended" ->
        put_change(changeset, :options, [])

      _ ->
        changeset
    end
  end
end
