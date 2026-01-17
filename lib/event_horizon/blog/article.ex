defmodule EventHorizon.Blog.Article do
  use Phoenix.Component
  use EventHorizonWeb.BlogComponents

  @type cover :: %{
          image: String.t(),
          alt: String.t(),
          caption: String.t()
        }

  @type body :: {:dynamic, Macro.t()} | {:static, String.t()}

  @type t :: %__MODULE__{
          slug: String.t(),
          title: String.t(),
          date: Date.t() | nil,
          description: String.t(),
          tags: [String.t()],
          body: body() | nil,
          dynamic: boolean(),
          read_minutes: non_neg_integer(),
          draft: boolean(),
          showToc: boolean(),
          cover: cover()
        }

  defstruct slug: "",
            title: "",
            date: nil,
            formatted_date: nil,
            description: "",
            tags: [],
            body: nil,
            dynamic: false,
            read_minutes: 0,
            draft: false,
            showToc: false,
            cover: %{
              image: "",
              alt: "",
              caption: ""
            }

  @spec build(String.t(), map(), body()) :: t()
  def build(filepath, attrs, body) do
    slug = Path.basename(filepath, ".md")
    read_minutes = compute_read_minutes(body)
    {:ok, date_time, _} = DateTime.from_iso8601(Map.fetch!(attrs, :date))
    date = DateTime.to_date(date_time)
    formatted_date = Calendar.strftime(date, "%B %d, %Y")

    struct!(
      __MODULE__,
      Map.merge(attrs, %{
        slug: slug,
        body: body,
        read_minutes: read_minutes,
        date: date,
        formatted_date: formatted_date
      })
    )
  end

  @words_per_minute 200

  defp compute_read_minutes({:static, html}) do
    html
    |> Floki.parse_fragment!()
    |> Floki.text()
    |> count_words()
    |> calculate_minutes()
  end

  defp compute_read_minutes({:dynamic, ast}) do
    render({:dynamic, ast}, %{})
    |> then(&Enum.join(&1.static, " "))
    |> count_words()
    |> calculate_minutes()
  end

  defp count_words(text) do
    text
    |> String.split(~r/\s+/, trim: true)
    |> Enum.count()
  end

  defp calculate_minutes(word_count) do
    max(1, ceil(word_count / @words_per_minute))
  end

  @spec render(body(), map()) :: Phoenix.LiveView.Rendered.t() | Phoenix.HTML.safe()
  def render({:dynamic, ast}, assigns) do
    {rendered, _} = Code.eval_quoted(ast, [assigns: assigns], __ENV__)
    rendered
  end

  def render({:static, html}, _assigns) do
    Phoenix.HTML.raw(html)
  end
end
