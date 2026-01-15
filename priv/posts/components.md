---
title: "Blog Components"
description: "This is all my blog components"
cover:
    image: "/public/blogImage.jpeg"
---

## Blog Components Examples

### Blockquote

<.blockquote>
This is a styled blockquote with a gradient border.
</.blockquote>

### Callouts

<.callout type="info">
This is an **info** callout for helpful tips and notes.
</.callout>

<.callout type="danger">
This is a **danger** callout for warnings and important notices.
</.callout>

### Cards

<.basic_card>
This is a basic card component.
</.basic_card>

<.card_with_title title="Featured Content">
This card has a title header with content inside.
</.card_with_title>

### Code with Filename

<.code filename="example.ex">
```elixir
defmodule Hello do
  def world, do: "Hello, World!"
end
```
</.code>

<.code filename="app.js">
```js
const greeting = "Hello from JavaScript!";
console.log(greeting);
```
</.code>

### Inline Code

Use <.codeblock>inline code</.codeblock> for small code snippets.

### Hidden Expand

<.hidden_expand summary="Click to expand details">
This content is hidden by default and expands when clicked.

You can put any content here including **markdown** formatting.
</.hidden_expand>

### Custom Lists

<.custom_ol>
  <li>First ordered item</li>
  <li>Second ordered item</li>
  <li>Third ordered item</li>
</.custom_ol>

<.custom_ul>
  <li>Unordered item one</li>
  <li>Unordered item two</li>
  <li>Unordered item three</li>
</.custom_ul>

### Styled Anchor

Check out <.styled_anchor href="https://github.com">GitHub</.styled_anchor> for more.

Internal link: <.styled_anchor href="#demo">Jump to Demo</.styled_anchor>
