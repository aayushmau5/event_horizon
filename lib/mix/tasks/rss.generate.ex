defmodule Mix.Tasks.Rss.Generate do
  @shortdoc "Generates the RSS feed XML file"
  @moduledoc """
  Generates the RSS feed from blog articles and writes it to priv/static/rss.xml.

  ## Usage

      $ mix rss.generate

  The generated file will be served at /rss.xml.
  """

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    # Ensure the app is compiled so Blog module is available
    Mix.Task.run("compile")

    output_path = Path.join([Application.app_dir(:event_horizon), "priv", "static", "rss.xml"])

    case EventHorizon.RSS.write_to_file(output_path) do
      :ok ->
        Mix.shell().info("RSS feed generated at #{output_path}")

      {:error, reason} ->
        Mix.shell().error("Failed to generate RSS feed: #{inspect(reason)}")
    end
  end
end
