defmodule Mix.Tasks.Post.New do
  @moduledoc "Create a new post. Run mix post.new \"my-new-post\""
  use Mix.Task

  @impl true
  def run(args) do
    path = Application.app_dir(:event_horizon, "priv/posts/")
    title = Enum.at(args, 0) || "new-post"
    description = Enum.at(args, 1) || "description"
    dynamic? = Enum.at(args, 2) === "--dynamic" || false
    File.write(Path.join(path, "#{title}.md"), init_blog_content(title, description, dynamic?))
    Mix.shell().info("Done!")
  end

  defp init_blog_content(title, description, dynamic?) do
    """
    ---
    title: "#{title}"
    description: "#{description}"
    date: #{DateTime.utc_now() |> DateTime.to_iso8601()}
    tags: []
    draft: true
    showToc: false
    dynamic: #{dynamic?}
    ---

    Hello World!
    """
  end
end
