defmodule EventHorizon.Blog do
  use NimblePublisher,
    from: Application.app_dir(:event_horizon, "priv/posts/*.md"),
    build: EventHorizon.Blog.Article,
    parser: EventHorizon.Blog.Parser,
    html_converter: EventHorizon.Blog.Converter,
    as: :blogs,
    highlighters: []

  @personal_tags ["life", "misc", "opinions", "reflection"]

  # Filter published blogs and sort by date (newest first)
  @articles @blogs
            |> Enum.reject(& &1.draft)
            |> Enum.sort_by(& &1.date, {:desc, Date})

  # Extract all unique tags from published articles
  @tags @articles
        |> Enum.flat_map(& &1.tags)
        |> Enum.uniq()
        |> Enum.reject(&(&1 in @personal_tags))
        |> Enum.sort()

  @doc """
  Returns all published articles, sorted by date (newest first).
  """
  def all_articles, do: @articles

  @doc """
  Returns all blogs (including drafts).
  """
  def all_blogs, do: @blogs

  @doc """
  Returns all unique tags (excluding category tags: life, misc, opinions).
  """
  def all_tags, do: @tags

  @doc """
  Returns the most recent articles.
  """
  def recent_articles(count \\ 3), do: Enum.take(all_articles(), count)

  @doc """
  Filters articles by category.

  ## Examples

      iex> articles_by_category("tech")
      iex> articles_by_category("life-opinions-misc")
  """
  def articles_by_category("tech") do
    Enum.reject(@articles, fn article ->
      has_any_tag?(article, @personal_tags)
    end)
  end

  def articles_by_category("life-opinions-misc") do
    Enum.filter(@articles, fn article ->
      has_any_tag?(article, @personal_tags)
    end)
  end

  def articles_by_category(_), do: @articles

  @doc """
  Filters articles by tag.
  """
  def articles_by_tag(nil), do: @articles
  def articles_by_tag(""), do: @articles

  def articles_by_tag(tag) do
    tag_lower = String.downcase(tag)

    Enum.filter(@articles, fn article ->
      Enum.any?(article.tags || [], fn t -> String.downcase(t) == tag_lower end)
    end)
  end

  @doc """
  Searches articles by title.
  """
  def search_articles(""), do: @articles
  def search_articles(nil), do: @articles

  def search_articles(query) do
    query_lower = String.downcase(query)

    Enum.filter(@articles, fn article ->
      String.contains?(String.downcase(article.title), query_lower)
    end)
  end

  @doc """
  Filters articles by multiple criteria.

  ## Options

    * `:category` - Filter by category ("tech" or "life-opinions-misc")
    * `:tag` - Filter by specific tag
    * `:search` - Search in article titles
  """
  def filter_articles(opts \\ []) do
    category = Keyword.get(opts, :category)
    tag = Keyword.get(opts, :tag)
    search = Keyword.get(opts, :search)

    @articles
    |> maybe_filter_by_category(category)
    |> maybe_filter_by_tag(tag)
    |> maybe_search(search)
  end

  @doc """
  Returns an article by its slug.
  """
  def get_article_by_slug(slug) do
    Enum.find(@articles, &(&1.slug == slug))
  end

  @spec get_blog(slug :: String.t()) :: EventHorizon.Blog.Article.t() | nil
  def get_blog(slug), do: get_article_by_slug(slug)

  @doc """
  Returns recommended articles for a given article.
  """
  def get_recommended_articles(current_article, count \\ 3) do
    all_articles()
    |> Enum.reject(&(&1.slug == current_article.slug))
    |> Enum.take_random(count)
  end

  # Private helpers

  defp has_any_tag?(article, tags) do
    Enum.any?(tags, fn tag ->
      tag in (article.tags || [])
    end)
  end

  defp maybe_filter_by_category(articles, nil), do: articles
  defp maybe_filter_by_category(articles, ""), do: articles

  defp maybe_filter_by_category(articles, "tech") do
    Enum.reject(articles, fn article ->
      has_any_tag?(article, @personal_tags)
    end)
  end

  defp maybe_filter_by_category(articles, "life-opinions-misc") do
    Enum.filter(articles, fn article ->
      has_any_tag?(article, @personal_tags)
    end)
  end

  defp maybe_filter_by_category(articles, _), do: articles

  defp maybe_filter_by_tag(articles, nil), do: articles
  defp maybe_filter_by_tag(articles, ""), do: articles

  defp maybe_filter_by_tag(articles, tag) do
    tag_lower = String.downcase(tag)

    Enum.filter(articles, fn article ->
      Enum.any?(article.tags || [], fn t -> String.downcase(t) == tag_lower end)
    end)
  end

  defp maybe_search(articles, nil), do: articles
  defp maybe_search(articles, ""), do: articles

  defp maybe_search(articles, query) do
    query_lower = String.downcase(query)

    Enum.filter(articles, fn article ->
      String.contains?(String.downcase(article.title), query_lower)
    end)
  end
end
