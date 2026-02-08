defmodule EventHorizon.Polls do
  @moduledoc """
  Context for managing polls, Q&A prompts, and their responses.
  """

  import Ecto.Query

  alias EventHorizon.Repo
  alias EventHorizon.Polls.Poll
  alias EventHorizon.Polls.PollResponse

  # -------------------------------------------------------------------
  # Polls
  # -------------------------------------------------------------------

  @doc """
  Returns all polls for a given blog slug, ordered by insertion time.
  """
  def list_polls_by_blog(blog_slug) do
    Poll
    |> where([p], p.blog_slug == ^blog_slug)
    |> order_by([p], asc: p.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single poll by id. Raises `Ecto.NoResultsError` if not found.
  """
  def get_poll!(id), do: Repo.get!(Poll, id)

  @doc """
  Gets a single poll by its slug. Returns `nil` if not found.
  """
  def get_poll_by_slug(slug), do: Repo.get_by(Poll, slug: slug)

  @doc """
  Creates a poll.
  """
  def create_poll(attrs) do
    %Poll{}
    |> Poll.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a poll.
  """
  def update_poll(%Poll{} = poll, attrs) do
    poll
    |> Poll.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a poll and all of its responses (via cascading delete).
  """
  def delete_poll(%Poll{} = poll) do
    Repo.delete(poll)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking poll changes.
  """
  def change_poll(%Poll{} = poll, attrs \\ %{}) do
    Poll.changeset(poll, attrs)
  end

  # -------------------------------------------------------------------
  # Responses
  # -------------------------------------------------------------------

  @doc """
  Returns all responses for a given poll id, ordered by insertion time.
  """
  def list_responses_by_poll(poll_id) do
    PollResponse
    |> where([r], r.poll_id == ^poll_id)
    |> order_by([r], asc: r.inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns all responses for every poll belonging to a blog slug,
  preloading the associated poll.
  """
  def list_responses_by_blog(blog_slug) do
    PollResponse
    |> join(:inner, [r], p in Poll, on: r.poll_id == p.id)
    |> where([_r, p], p.blog_slug == ^blog_slug)
    |> order_by([r, _p], asc: r.inserted_at)
    |> preload([_r, p], poll: p)
    |> Repo.all()
  end

  @doc """
  Creates a response for a poll.

  If the respondent has already answered this poll, returns
  `{:error, changeset}` with the unique constraint violation.
  """
  def create_response(%Poll{} = poll, attrs) do
    %PollResponse{}
    |> PollResponse.changeset(attrs, poll)
    |> Repo.insert()
  end

  @doc """
  Updates an existing response (e.g. changing a vote or editing an answer).
  """
  def update_response(%PollResponse{} = response, %Poll{} = poll, attrs) do
    response
    |> PollResponse.changeset(attrs, poll)
    |> Repo.update()
  end

  @doc """
  Gets an existing response for a poll (by slug) and respondent.
  Returns `nil` if no response found.
  """
  def get_response_by_poll_slug_and_respondent(poll_slug, respondent_id) do
    PollResponse
    |> join(:inner, [r], p in Poll, on: r.poll_id == p.id)
    |> where([r, p], p.slug == ^poll_slug and r.respondent_id == ^respondent_id)
    |> preload([_r, p], poll: p)
    |> Repo.one()
  end

  @doc """
  Finds a poll by slug, or creates it with the given attributes.
  Used when polls are defined inline in blog markdown.
  """
  def find_or_create_poll(slug, attrs) do
    case get_poll_by_slug(slug) do
      nil ->
        create_poll(Map.put(attrs, :slug, slug))

      poll ->
        {:ok, poll}
    end
  end
end
