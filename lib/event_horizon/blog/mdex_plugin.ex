defmodule EventHorizon.Blog.MDExPlugin do
  @moduledoc """
  MDEx plugin that transforms markdown AST nodes into custom Phoenix components.
  """

  @blockquote_regex ~r/^\((\w+)(?::\s*"([^"]*)")?\)\s*/
  @escape_map %{"&" => "&amp;", "<" => "&lt;", ">" => "&gt;", "{" => "&#123;", "}" => "&#125;"}

  def transform(document), do: MDEx.traverse_and_update(document, &transform_node/1)

  defp transform_node(%MDEx.BlockQuote{nodes: nodes}),
    do: nodes |> extract_blockquote_type() |> render_blockquote()

  defp transform_node(%MDEx.CodeBlock{info: info, literal: code}) do
    {lang, attrs} = parse_code_info(info)
    html = wrap_code(highlight_code(code, lang), attrs["filename"])
    %MDEx.HtmlBlock{literal: html}
  end

  defp transform_node(%MDEx.Code{literal: code}),
    do: %MDEx.HtmlInline{literal: "<.codeblock>#{escape_heex(code)}</.codeblock>"}

  defp transform_node(%MDEx.List{list_type: type, start: start, nodes: nodes}) do
    {tag, attrs} =
      case type do
        :ordered -> {"ol", if(start != 1, do: ~s( start="#{start}"), else: "")}
        :bullet -> {"ul", ""}
      end

    %MDEx.HtmlBlock{
      literal: ~s(<#{tag} class="custom-#{tag}"#{attrs}>\n#{render_nodes(nodes)}\n</#{tag}>)
    }
  end

  defp transform_node(%MDEx.Link{url: url, nodes: nodes}),
    do: %MDEx.HtmlInline{
      literal:
        ~s(<.styled_anchor href="#{escape_attr(url)}">#{render_nodes(nodes)}</.styled_anchor>)
    }

  defp transform_node(node), do: node

  defp render_nodes(nodes) do
    MDEx.new()
    |> Map.put(:nodes, nodes)
    |> MDEx.traverse_and_update(&transform_node/1)
    |> MDEx.to_html!(render: [unsafe: true, escape: false])
  end

  defp extract_blockquote_type([
         %MDEx.Paragraph{nodes: [%MDEx.Text{literal: text} | rest]} | other
       ]) do
    case Regex.run(@blockquote_regex, text) do
      [match, type | args] ->
        arg = List.first(args)
        remaining = String.trim_leading(text, match)
        {{String.to_atom(type), arg}, rebuild_nodes(remaining, rest, other)}

      nil ->
        {:blockquote, [%MDEx.Paragraph{nodes: [%MDEx.Text{literal: text} | rest]} | other]}
    end
  end

  defp extract_blockquote_type(nodes), do: {:blockquote, nodes}

  defp rebuild_nodes("", [], other), do: other
  defp rebuild_nodes("", rest, other), do: [%MDEx.Paragraph{nodes: rest} | other]

  defp rebuild_nodes(text, rest, other),
    do: [%MDEx.Paragraph{nodes: [%MDEx.Text{literal: text} | rest]} | other]

  defp render_blockquote({type, nodes}) do
    inner = render_nodes(nodes)

    literal =
      case type do
        {:info, _} ->
          ~s(<.callout type="info">\n#{inner}\n</.callout>)

        {:danger, _} ->
          ~s(<.callout type="danger">\n#{inner}\n</.callout>)

        {:card, nil} ->
          ~s(<.basic_card>\n#{inner}\n</.basic_card>)

        {:card, title} ->
          ~s(<.card_with_title title="#{escape_attr(title)}">\n#{inner}\n</.card_with_title>)

        {:details, summary} ->
          ~s(<.hidden_expand summary="#{escape_attr(summary)}">\n#{inner}\n</.hidden_expand>)

        _ ->
          ~s(<.blockquote>\n#{inner}\n</.blockquote>)
      end

    %MDEx.HtmlBlock{literal: literal}
  end

  defp wrap_code(html, nil), do: html

  defp wrap_code(html, filename),
    do: ~s(<.code filename="#{escape_attr(filename)}">\n#{html}\n</.code>)

  defp parse_code_info(info) when info in [nil, ""], do: {"", %{}}

  defp parse_code_info(info) do
    case String.split(info, ~r/\s+/, trim: true) do
      [] -> {"", %{}}
      [lang | attrs] -> {lang, Map.new(attrs, &parse_attr/1)}
    end
  end

  defp parse_attr(attr) do
    case String.split(attr, "=", parts: 2) do
      [key, value] -> {key, String.trim(value, "\"")}
      [key] -> {key, true}
    end
  end

  defp escape_heex(text), do: String.replace(text, Map.keys(@escape_map), &@escape_map[&1])

  defp escape_attr(text),
    do: text |> String.replace("\"", "&quot;") |> String.replace(~r/[<>]/, &@escape_map[&1])

  defp highlight_code(code, lang) when lang in ["", nil],
    do: "<pre class=\"custom-pre\"><code>#{escape_heex(code)}</code></pre>"

  defp highlight_code(code, lang) do
    code
    |> Autumn.highlight!(language: lang, formatter: {:html_inline, theme: "kanagawa_wave"})
    |> String.replace(~r/[{}]/, &@escape_map[&1])
  rescue
    _ -> ~s(<pre><code class="language-#{lang}">#{escape_heex(code)}</code></pre>)
  end
end
