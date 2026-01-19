<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
      <head>
        <title><xsl:value-of select="/rss/channel/title"/> | RSS Feed</title>
        <meta charset="utf-8"/>
        <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <style type="text/css">
          :root {
            --bg:rgb(21, 21, 23);
            --bg-secondary:rgb(27, 28, 34);
            --text: #c0caf5;
            --text-muted: #565f89;
            --accent: #7aa2f7;
            --accent-secondary: #bb9af7;
            --border: #414868;
          }

          * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
          }

          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, sans-serif;
            background-color: var(--bg);
            color: var(--text);
            line-height: 1.6;
            padding: 2rem;
            max-width: 800px;
            margin: 0 auto;
          }

          .header {
            text-align: center;
            padding-bottom: 2rem;
            border-bottom: 1px solid var(--border);
          }

          h1 {
            font-size: 1.75rem;
            font-weight: 700;
            margin-bottom: 0.5rem;
            color: var(--text);
          }

          .description {
            color: var(--text-muted);
            font-size: 1rem;
          }

          .posts {
            display: flex;
            flex-direction: column;
            gap: 1rem;
          }

          .post {
            background-color: var(--bg-secondary);
            border: 1px solid var(--border);
            padding: 1.25rem;
            transition: border-color 0.2s ease;
          }

          .post:hover {
            border-color: var(--accent);
          }

          .post-title {
            font-size: 1.125rem;
            font-weight: 600;
            margin-bottom: 0.5rem;
          }

          .post-title a {
            color: var(--text);
            text-decoration: none;
          }

          .post-title a:hover {
            color: var(--accent);
          }

          .post-description {
            color: var(--text-muted);
            font-size: 0.875rem;
            margin-bottom: 0.75rem;
          }

          .post-date {
            font-size: 0.75rem;
            color: var(--text-muted);
          }

          .backlink {
            text-align: center;
            margin-bottom: 3rem;
            padding: 1rem 0;
            border-bottom: 1px solid var(--border);
            color: var(--text-muted);
            font-size: 0.875rem;
          }

          .backlink a {
            color: var(--accent);
            text-decoration: none;
          }

          .backlink a:hover {
            text-decoration: underline;
          }

          @media (max-width: 600px) {
            body {
              padding: 1rem;
            }

            h1 {
              font-size: 1.5rem;
            }
          }
        </style>
      </head>
      <body>
        <div class="header">
          <span class="rss-badge">RSS Feed</span>
          <h1><xsl:value-of select="/rss/channel/title"/></h1>
          <p class="description"><xsl:value-of select="/rss/channel/description"/></p>
        </div>

        <div class="backlink">
          <p>
            <a>
              <xsl:attribute name="href">
                <xsl:value-of select="/rss/channel/link"/>
              </xsl:attribute>
              ← Go back to aayushsahu.com
            </a>
          </p>
        </div>

        <div class="posts">
          <xsl:for-each select="/rss/channel/item">
            <article class="post">
              <h2 class="post-title">
                <a>
                  <xsl:attribute name="href">
                    <xsl:value-of select="link"/>
                  </xsl:attribute>
                  <xsl:value-of select="title"/>
                </a>
              </h2>
              <xsl:if test="description">
                <p class="post-description">
                  <xsl:value-of select="description"/>
                </p>
              </xsl:if>
              <p class="post-date">
                <xsl:value-of select="pubDate"/>
              </p>
            </article>
          </xsl:for-each>
        </div>

      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
