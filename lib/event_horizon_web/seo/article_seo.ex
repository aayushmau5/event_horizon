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
          url: cloudinary_og_image(article.title),
          alt: article.title
        ),
      detail:
        SEO.OpenGraph.Article.build(
          published_time: article.date,
          author: "Aayush Kumar Sahu"
        )
    )
  end

  defp cloudinary_og_image(title) do
    cloud_name = "dbsdoq31k"
    image_public_id = "blog_banner.png"
    version = "v1641893609"

    image_config = "w_1200,h_630,c_fill,f_auto"

    title_config =
      [
        "w_600",
        "h_430",
        "c_fit",
        "co_rgb:BBBBBB",
        "y_-40",
        "x_290",
        "l_text:roboto_40_bold:#{URI.encode(title)}"
      ]
      |> Enum.join(",")

    "https://res.cloudinary.com/#{cloud_name}/image/upload/#{image_config},#{title_config}/#{version}/#{image_public_id}"
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
      image: cloudinary_og_image(article.title)
    )
  end

  # TODO: replace this with inhouse solution
  defp cloudinary_og_image(title) do
    cloud_name = "dbsdoq31k"
    image_public_id = "blog_banner.png"
    version = "v1641893609"

    image_config = "w_1200,h_630,c_fill,f_auto"

    title_config =
      [
        "w_600",
        "h_430",
        "c_fit",
        "co_rgb:BBBBBB",
        "y_-40",
        "x_290",
        "l_text:roboto_40_bold:#{URI.encode(title)}"
      ]
      |> Enum.join(",")

    "https://res.cloudinary.com/#{cloud_name}/image/upload/#{image_config},#{title_config}/#{version}/#{image_public_id}"
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
