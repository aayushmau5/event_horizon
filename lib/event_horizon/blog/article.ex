defmodule EventHorizon.Blog.Article do
  use Phoenix.Component

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

  def build(filepath, attrs, body) do
    slug = Path.basename(filepath, ".mdex")

    struct!(
      __MODULE__,
      Map.merge(attrs, %{slug: slug, body: body, read_minutes: 0})
    )
  end

  def render(%__MODULE__{body: {:dynamic, ast}}, assigns) do
    {rendered, _} = Code.eval_quoted(ast, [assigns: assigns], __ENV__)
    rendered
  end

  def render(%__MODULE__{body: {:static, html}}, _assigns) do
    Phoenix.HTML.raw(html)
  end
end
