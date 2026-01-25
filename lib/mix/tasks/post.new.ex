defmodule Mix.Tasks.Post.New do
  @moduledoc """
  Create a new post.

  Usage: mix post.new "Post Title" --slug my-post-slug [--description "..."] [--dynamic]

  ## Options

    * `--slug` - (required) the slug for the post filename
    * `--description` - (optional) post description, can also be passed as second positional arg
    * `--dynamic` - (optional) mark the post as dynamic

  ## Examples

      mix post.new "My New Post" --slug my-new-post
      mix post.new "My New Post" "A description" --slug my-new-post --dynamic
      mix post.new "My New Post" --slug my-new-post --description "A description"
  """
  use Mix.Task

  @switches [slug: :string, description: :string, dynamic: :boolean]

  @impl true
  def run(args) do
    {opts, positional, _invalid} = OptionParser.parse(args, strict: @switches)

    title = Enum.at(positional, 0)
    slug = Keyword.get(opts, :slug)

    unless title && slug do
      Mix.raise("Missing required arguments. Usage: mix post.new \"Title\" --slug my-slug")
    end

    description = Keyword.get(opts, :description) || Enum.at(positional, 1) || ""
    dynamic? = Keyword.get(opts, :dynamic, false)

    path = Application.app_dir(:event_horizon, "priv/posts/")
    File.write(Path.join(path, "#{slug}.md"), init_blog_content(title, description, dynamic?))
    Mix.shell().info("Created post: #{slug}.md")
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
