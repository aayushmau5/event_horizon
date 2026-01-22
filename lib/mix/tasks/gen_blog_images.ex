defmodule Mix.Tasks.GenBlogImages do
  @shortdoc "Generates SEO images for all blog posts"
  @moduledoc """
  Generates Open Graph images for all blog posts.

  ## Usage

      mix gen_blog_images

  Images are saved to priv/static/images/banners/{slug}.webp
  """
  use Mix.Task

  @output_dir "priv/static/images/banners"

  @impl Mix.Task
  def run(_args) do
    Application.ensure_all_started(:event_horizon)

    File.mkdir_p!(@output_dir)

    articles = EventHorizon.Blog.all_articles()
    total = length(articles)

    Mix.shell().info("Generating #{total} blog images...")

    articles
    |> Enum.with_index(1)
    |> Enum.each(fn {article, idx} ->
      output_path = Path.join(@output_dir, "#{article.slug}.webp")

      case EventHorizon.BlogImage.generate(article.title, output_path) do
        {:ok, _path} ->
          Mix.shell().info("[#{idx}/#{total}] ✓ #{article.slug}")

        {:error, reason} ->
          Mix.shell().error("[#{idx}/#{total}] ✗ #{article.slug}: #{inspect(reason)}")
      end
    end)

    Mix.shell().info("Done!")
  end
end
