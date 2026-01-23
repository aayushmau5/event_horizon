defmodule EventHorizon.BlogImage do
  @moduledoc """
  Generates blog SEO/Open Graph images with title overlay.
  """

  @banner_path "priv/static/blog_banner.webp"

  def generate(title, output_path) do
    with {:ok, bg} <- Image.open(@banner_path),
         {:ok, title_text} <-
           Image.Text.text(title,
             font: "IBM Plex Sans",
             font_size: 30,
             text_fill_color: :white,
             width: 400,
             align: :left
           ) do
      bg
      |> Image.compose!(title_text, x: -40, y: :middle)
      |> Image.write!(output_path)

      {:ok, output_path}
    end
  end
end
