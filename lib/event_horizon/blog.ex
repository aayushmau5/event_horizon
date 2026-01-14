defmodule EventHorizon.Blog do
  use NimblePublisher,
    from: Application.app_dir(:event_horizon, "priv/posts/*.md"),
    build: EventHorizon.Blog.Article,
    parser: EventHorizon.Blog.Parser,
    html_converter: EventHorizon.Blog.Converter,
    as: :blogs,
    highlighters: []

  def all_blogs, do: @blogs
end
