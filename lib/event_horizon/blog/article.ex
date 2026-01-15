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

    struct!(
      __MODULE__,
      Map.merge(attrs, %{slug: slug, body: body, read_minutes: 0})
    )
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
