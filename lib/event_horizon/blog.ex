defmodule EventHorizon.Blog do
  use NimblePublisher,
    from: Application.app_dir(:event_horizon, "priv/posts/*.md"),
    build: EventHorizon.Blog.Article,
    parser: EventHorizon.Blog.Parser,
    html_converter: EventHorizon.Blog.Converter,
    as: :blogs,
    highlighters: []

  def all_blogs, do: @blogs

  @spec list_blogs() :: term()
  def list_blogs do
    Enum.map(all_blogs(), fn blog ->
      %{
        title: blog.title,
        slug: blog.slug,
        date: blog.date,
        read_minutes: blog.read_minutes
      }
    end)
  end

  @spec get_blog(slug :: String.t()) :: EventHorizon.Blog.Article.t() | nil
  def get_blog(slug) do
    all_blogs()
    |> Enum.find(fn %{slug: blog_slug} -> blog_slug == slug end)
  end
end
