defmodule Mix.Tasks.Sitemap.Generate do
  @shortdoc "Generates the sitemap XML file"

  @moduledoc """
  Generates the sitemap from static pages and blog articles.

  ## Usage

      $ mix sitemap.generate

  The generated file will be served at /sitemap.xml.
  """
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    output_path =
      Path.join([Application.app_dir(:event_horizon), "priv", "static", "sitemap.xml"])

    case EventHorizon.Sitemap.write_to_file(output_path) do
      :ok ->
        Mix.shell().info("Sitemap generated at #{output_path}")

      {:error, reason} ->
        Mix.shell().error("Failed to generate sitemap: #{inspect(reason)}")
    end
  end
end
