defmodule EventHorizonWeb.SEO do
  use EventHorizonWeb, :verified_routes

  @site_url "https://aayush-event-horizon.fly.dev"
  @site_title "Aayush Kumar Sahu"
  @site_description "Developer and Explorer"
  @social_image "/socialBanner.png"
  @twitter_handle "@aayushmau5"

  use SEO,
    json_library: Jason,
    site: &__MODULE__.site_config/1,
    open_graph:
      SEO.OpenGraph.build(
        description: @site_description,
        site_name: @site_title,
        locale: "en_US",
        image:
          SEO.OpenGraph.Image.build(
            url: @site_url <> @social_image,
            alt: @site_title
          )
      ),
    twitter:
      SEO.Twitter.build(
        site: @twitter_handle,
        card: :summary_large_image,
        image: @site_url <> @social_image
      )

  def site_config(_conn) do
    SEO.Site.build(
      default_title: @site_title,
      description: @site_description,
      title_suffix: ""
    )
  end

  def site_url, do: @site_url
  def default_og_image, do: @site_url <> @social_image
end
