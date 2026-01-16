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
    {block_type, remaining_nodes} = extract_blockquote_type(nodes)
    render_blockquote(block_type, remaining_nodes)
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
    %MDEx.HtmlBlock{literal: "<ol class=\"custom-ol\"#{start_attr}>\n#{inner}\n</ol>"}
  end

  defp transform_node(%MDEx.List{list_type: :bullet, nodes: nodes}) do
    inner = render_nodes(nodes)
    %MDEx.HtmlBlock{literal: "<ul class=\"custom-ul\">\n#{inner}\n</ul>"}
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

  # Blockquote type extraction and rendering
  # Supports: (info), (danger), (card), (card: "title"), or plain blockquote

  defp extract_blockquote_type([
         %MDEx.Paragraph{nodes: [%MDEx.Text{literal: text} | rest]} | other_nodes
       ]) do
    case Regex.run(~r/^\((\w+)(?::\s*"([^"]*)")?\)\s*/, text) do
      [full_match, type] ->
        remaining_text = String.trim_leading(text, full_match)
        updated_nodes = rebuild_paragraph_nodes(remaining_text, rest, other_nodes)
        {{String.to_atom(type), nil}, updated_nodes}

      [full_match, type, arg] ->
        remaining_text = String.trim_leading(text, full_match)
        updated_nodes = rebuild_paragraph_nodes(remaining_text, rest, other_nodes)
        {{String.to_atom(type), arg}, updated_nodes}

      nil ->
        {:blockquote, [%MDEx.Paragraph{nodes: [%MDEx.Text{literal: text} | rest]} | other_nodes]}
    end
  end

  defp extract_blockquote_type(nodes), do: {:blockquote, nodes}

  defp rebuild_paragraph_nodes("", [], other_nodes), do: other_nodes

  defp rebuild_paragraph_nodes("", rest, other_nodes),
    do: [%MDEx.Paragraph{nodes: rest} | other_nodes]

  defp rebuild_paragraph_nodes(text, rest, other_nodes) do
    [%MDEx.Paragraph{nodes: [%MDEx.Text{literal: text} | rest]} | other_nodes]
  end

  defp render_blockquote(:blockquote, nodes) do
    inner = render_nodes(nodes)
    %MDEx.HtmlBlock{literal: "<.blockquote>\n#{inner}\n</.blockquote>"}
  end

  defp render_blockquote({:info, _}, nodes) do
    inner = render_nodes(nodes)
    %MDEx.HtmlBlock{literal: "<.callout type=\"info\">\n#{inner}\n</.callout>"}
  end

  defp render_blockquote({:danger, _}, nodes) do
    inner = render_nodes(nodes)
    %MDEx.HtmlBlock{literal: "<.callout type=\"danger\">\n#{inner}\n</.callout>"}
  end

  defp render_blockquote({:card, nil}, nodes) do
    inner = render_nodes(nodes)
    %MDEx.HtmlBlock{literal: "<.basic_card>\n#{inner}\n</.basic_card>"}
  end

  defp render_blockquote({:card, title}, nodes) do
    inner = render_nodes(nodes)

    %MDEx.HtmlBlock{
      literal: "<.card_with_title title=\"#{escape_attr(title)}\">\n#{inner}\n</.card_with_title>"
    }
  end

  defp render_blockquote(_, nodes) do
    inner = render_nodes(nodes)
    %MDEx.HtmlBlock{literal: "<.blockquote>\n#{inner}\n</.blockquote>"}
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
    "<pre class=\"custom-pre\"><code>#{escape_heex(code)}</code></pre>"
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
