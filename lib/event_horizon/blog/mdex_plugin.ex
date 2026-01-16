defmodule EventHorizon.Blog.MDExPlugin do
  @moduledoc """
  MDEx plugin that transforms markdown AST nodes into custom Phoenix components.

  Customizes:
  - Blockquotes (`>`) → `<.blockquote>`
  - Code blocks with `filename=` → `<.code filename="...">`
  - Inline code → `<.codeblock>`
  - Lists → `<.custom_ol>` / `<.custom_ul>`
  - Links → `<.styled_anchor>`
  - Pre blocks → `<.pre>`
  """

  def transform(document) do
    MDEx.traverse_and_update(document, &transform_node/1)
  end

  defp transform_node(%MDEx.BlockQuote{nodes: nodes}) do
    inner = render_nodes(nodes)
    %MDEx.HtmlBlock{literal: "<.blockquote>\n#{inner}\n</.blockquote>"}
  end

  defp transform_node(%MDEx.CodeBlock{info: info, literal: code}) do
    {lang, attrs} = parse_code_info(info)
    filename = get_attr(attrs, "filename")

    highlighted_code = highlight_code(code, lang)

    literal =
      if filename do
        """
        <.code filename="#{escape_attr(filename)}">
        #{highlighted_code}
        </.code>
        """
      else
        highlighted_code
      end

    %MDEx.HtmlBlock{literal: literal}
  end

  defp transform_node(%MDEx.Code{literal: code}) do
    %MDEx.HtmlInline{literal: "<.codeblock>#{escape_heex(code)}</.codeblock>"}
  end

  defp transform_node(%MDEx.List{list_type: :ordered, start: start, nodes: nodes}) do
    inner = render_nodes(nodes)
    start_attr = if start != 1, do: ~s( start="#{start}"), else: ""
    %MDEx.HtmlBlock{literal: "<.custom_ol#{start_attr}>\n#{inner}\n</.custom_ol>"}
  end

  defp transform_node(%MDEx.List{list_type: :bullet, nodes: nodes}) do
    inner = render_nodes(nodes)
    %MDEx.HtmlBlock{literal: "<.custom_ul>\n#{inner}\n</.custom_ul>"}
  end

  defp transform_node(%MDEx.Link{url: url, nodes: nodes}) do
    inner = render_nodes(nodes)

    %MDEx.HtmlInline{
      literal: ~s(<.styled_anchor href="#{escape_attr(url)}">#{inner}</.styled_anchor>)
    }
  end

  defp transform_node(node), do: node

  defp render_nodes(nodes) do
    doc =
      MDEx.new()
      |> Map.put(:nodes, nodes)
      |> MDEx.traverse_and_update(&transform_node/1)

    MDEx.to_html!(doc, render: [unsafe: true, escape: false])
  end

  defp parse_code_info(nil), do: {"", []}
  defp parse_code_info(""), do: {"", []}

  defp parse_code_info(info) do
    parts = String.split(info, ~r/\s+/, trim: true)

    case parts do
      [] -> {"", []}
      [lang | attrs] -> {lang, attrs}
    end
  end

  defp get_attr(attrs, key) do
    Enum.find_value(attrs, fn attr ->
      case String.split(attr, "=", parts: 2) do
        [^key, value] -> String.trim(value, "\"")
        _ -> nil
      end
    end)
  end

  defp escape_heex(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("{", "&#123;")
    |> String.replace("}", "&#125;")
  end

  defp escape_attr(text) do
    text
    |> String.replace("\"", "&quot;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp highlight_code(code, lang) when lang in ["", nil] do
    "<pre><code>#{escape_heex(code)}</code></pre>"
  end

  defp highlight_code(code, lang) do
    case Autumn.highlight!(code, language: lang, formatter: {:html_inline, theme: "onedark"}) do
      highlighted when is_binary(highlighted) ->
        highlighted
        |> String.replace("{", "&#123;")
        |> String.replace("}", "&#125;")

      _ ->
        "<pre><code class=\"language-#{lang}\">#{escape_heex(code)}</code></pre>"
    end
  rescue
    _ -> "<pre><code class=\"language-#{lang}\">#{escape_heex(code)}</code></pre>"
  end
end
