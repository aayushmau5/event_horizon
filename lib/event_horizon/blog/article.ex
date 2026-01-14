defmodule EventHorizon.Blog.Article do
  defstruct slug: "",
            title: "",
            date: nil,
            description: "",
            tags: [],
            body: "",
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
    dbg(attrs)

    struct!(
      __MODULE__,
      Map.merge(attrs, %{slug: slug, body: body, read_minutes: 0})
    )
  end
end
