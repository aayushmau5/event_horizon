defmodule EventHorizon.Sitemap do
  @moduledoc """
  Generates sitemap.xml from static pages and blog articles at build time.
  """

  alias EventHorizon.Blog

  @site_url "https://aayushsahu.com"

  @static_pages [
    %{loc: "/", priority: "1.0", changefreq: "weekly"},
    %{loc: "/blog", priority: "0.9", changefreq: "daily"},
    %{loc: "/projects", priority: "0.8", changefreq: "monthly"},
    %{loc: "/about", priority: "0.7", changefreq: "monthly"},
    %{loc: "/books", priority: "0.6", changefreq: "monthly"},
    %{loc: "/uses", priority: "0.6", changefreq: "monthly"},
    %{loc: "/links", priority: "0.5", changefreq: "monthly"},
    %{loc: "/contact", priority: "0.5", changefreq: "yearly"}
  ]

  @doc """
  Generates the sitemap XML string.
  """
  def generate do
    articles = Blog.all_articles()

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{generate_static_urls()}
    #{generate_article_urls(articles)}
    </urlset>
    """
    |> String.trim()
  end

  defp generate_static_urls do
    @static_pages
    |> Enum.map(fn page ->
      """
        <url>
          <loc>#{@site_url}#{page.loc}</loc>
          <changefreq>#{page.changefreq}</changefreq>
          <priority>#{page.priority}</priority>
        </url>
      """
    end)
    |> Enum.join()
  end

  defp generate_article_urls(articles) do
    articles
    |> Enum.map(fn article ->
      """
        <url>
          <loc>#{@site_url}/blog/#{article.slug}</loc>
          <lastmod>#{Date.to_iso8601(article.date)}</lastmod>
          <changefreq>monthly</changefreq>
          <priority>0.8</priority>
        </url>
      """
    end)
    |> Enum.join()
  end

  @doc """
  Writes the sitemap to the given path.
  """
  def write_to_file(path) do
    File.write(path, generate())
  end
end
