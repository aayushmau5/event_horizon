defmodule EventHorizon.RSS do
  @moduledoc """
  Generates RSS feed XML from blog articles at build time.
  """

  alias EventHorizon.Blog

  @site_url "https://aayushsahu.com"
  @site_title "Aayush Kumar Sahu - Developer and Explorer"
  @site_description "Welcome to aayush's digital garden!"

  @doc """
  Generates the RSS feed XML string from all published blog articles.
  """
  @spec generate :: String.t()
  def generate do
    articles = Blog.all_articles()
    build_date = Calendar.strftime(DateTime.utc_now(), "%a, %d %b %Y %H:%M:%S GMT")

    """
    <?xml version="1.0" encoding="utf-8"?>
    <?xml-stylesheet type="text/xsl" href="/rss-styles.xsl"?>
    <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
        <channel>
            <title>#{escape_xml(@site_title)}</title>
            <link>#{@site_url}</link>
            <description>#{escape_xml(@site_description)}</description>
            <lastBuildDate>#{build_date}</lastBuildDate>
            <docs>https://validator.w3.org/feed/docs/rss2.html</docs>
            <generator>EventHorizon RSS Generator</generator>
            <language>en</language>
            <atom:link href="#{@site_url}/rss.xml" rel="self" type="application/rss+xml"/>
            <atom:icon>#{@site_url}/favicon.ico</atom:icon>
            <image>
                <title>#{escape_xml(@site_title)}</title>
                <url>#{@site_url}/socialBanner.png</url>
                <link>#{@site_url}</link>
            </image>
            <copyright>CC #{Date.utc_today().year}, Aayush Kumar Sahu</copyright>
            <category>Programming</category>
    #{build_items(articles)}</channel>
    </rss>
    """
  end

  @doc """
  Writes the RSS feed to the given path.
  """
  @spec write_to_file(String.t()) :: :ok | {:error, term()}
  def write_to_file(path) do
    content = generate()
    File.write(path, content)
  end

  defp build_items(articles) do
    articles
    |> Enum.map(&build_item/1)
    |> Enum.join("\n")
  end

  defp build_item(article) do
    pub_date = format_pub_date(article.date)
    link = "#{@site_url}/blog/#{article.slug}"

    description_content =
      if article.description && article.description != "" do
        ["            <description><![CDATA[#{article.description}]]></description>"]
      else
        []
      end

    lines =
      [
        "        <item>",
        "            <title><![CDATA[#{article.title}]]></title>",
        "            <link>#{link}</link>",
        "            <guid>#{link}</guid>",
        "            <pubDate>#{pub_date}</pubDate>"
      ] ++ description_content ++ ["        </item>"]

    Enum.join(lines, "\n")
  end

  defp format_pub_date(date) do
    # Convert Date to DateTime at midnight UTC, then format as RFC 822
    {:ok, datetime} = DateTime.new(date, ~T[00:00:00], "Etc/UTC")
    Calendar.strftime(datetime, "%a, %d %b %Y %H:%M:%S GMT")
  end

  defp escape_xml(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
