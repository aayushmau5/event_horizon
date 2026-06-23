defimpl SEO.OpenGraph.Build, for: EventHorizon.Blog.Article do
  use EventHorizonWeb, :verified_routes

  def build(article, _conn) do
    SEO.OpenGraph.build(
      title: article.title,
      description: article.description,
      url: EventHorizonWeb.SEO.site_url() <> "/blog/#{article.slug}",
      type: :article,
      image:
        SEO.OpenGraph.Image.build(
          url: og_image_url(article),
          alt: article.title
        ),
      detail:
        SEO.OpenGraph.Article.build(
          published_time: article.date,
          author: "Aayush Kumar Sahu"
        )
    )
  end

  defp og_image_url(%{cover: %{image: image}} = _article) when image != "" do
    EventHorizonWeb.SEO.site_url() <> image
  end

  defp og_image_url(article) do
    EventHorizonWeb.SEO.site_url() <> "/images/banners/#{article.slug}.webp"
  end
end

defimpl SEO.Site.Build, for: EventHorizon.Blog.Article do
  use EventHorizonWeb, :verified_routes

  def build(article, _conn) do
    SEO.Site.build(
      title: article.title,
      description: article.description,
      canonical_url: EventHorizonWeb.SEO.site_url() <> "/blog/#{article.slug}"
    )
  end
end

defimpl SEO.Twitter.Build, for: EventHorizon.Blog.Article do
  def build(article, _conn) do
    SEO.Twitter.build(
      title: article.title,
      description: article.description,
      card: :summary_large_image,
      image: og_image_url(article)
    )
  end

  defp og_image_url(%{cover: %{image: image}} = _article) when image != "" do
    EventHorizonWeb.SEO.site_url() <> image
  end

  defp og_image_url(article) do
    EventHorizonWeb.SEO.site_url() <> "/images/banners/#{article.slug}.webp"
  end
end

defimpl SEO.Breadcrumb.Build, for: EventHorizon.Blog.Article do
  use EventHorizonWeb, :verified_routes

  def build(article, _conn) do
    site_url = EventHorizonWeb.SEO.site_url()

    SEO.Breadcrumb.List.build([
      %{name: "Blog", item: site_url <> "/blog"},
      %{name: article.title, item: site_url <> "/blog/#{article.slug}"}
    ])
  end
end
