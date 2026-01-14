defmodule EventHorizon.Blog.Parser do
  use Phoenix.Component

  def parse(_path, content) do
    {frontmatter, body} = parse_frontmatter!(content)
    body = convert_body!(body)
    {frontmatter, body}
  end

  defp parse_frontmatter!(content) do
    case String.split(content, ~r/\n---\n/, parts: 2) do
      ["---" <> yaml_content, body] ->
        frontmatter =
          yaml_content
          |> YamlElixir.read_from_string!()
          |> atomize_keys()

        {frontmatter, body}

      _ ->
        raise "Failed to get the frontmatter"
    end
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_existing_atom(k), atomize_keys(v)} end)
  end

  defp atomize_keys(value), do: value

  defp convert_body!(body) do
    html_body = markdown_to_html!(body)
    env = __ENV__

    ast =
      EEx.compile_string(html_body,
        engine: Phoenix.LiveView.TagEngine,
        file: env.file,
        line: env.line + 1,
        caller: env,
        indentation: 0,
        source: html_body,
        tag_handler: Phoenix.LiveView.HTMLEngine
      )

    assigns = %{}

    {rendered, _} = Code.eval_quoted(ast, [assigns: assigns], env)

    rendered |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp markdown_to_html!(markdown) do
    MDEx.to_html!(markdown,
      extension: [
        phoenix_heex: true
      ],
      render: [
        unsafe: true,
      ]
    )
  end
end
