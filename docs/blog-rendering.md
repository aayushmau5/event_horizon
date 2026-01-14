# Blog Rendering Approaches

This document explains how blog posts are rendered in EventHorizon, supporting both static and dynamic content with Phoenix HEEx components.

## The Problem

We want to write blog posts in Markdown (`.md` files) that can include:

- Standard Markdown syntax
- Phoenix HEEx components like `<.link>`
- Dynamic Elixir expressions like `{@count}`
- LiveView bindings like `phx-click`

The challenge is balancing **performance** with **interactivity**.

---

## Two Rendering Modes

Control the mode via the `dynamic` frontmatter key:

```yaml
---
title: "My Post"
dynamic: true   # Interactive mode
---
```

```yaml
---
title: "My Post"
dynamic: false  # Static mode (default)
---
```

---

## Static Mode (Default)

**Best for:** Regular blog posts without interactive elements.

### How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                        BUILD TIME                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Markdown          HEEx HTML           AST            HTML     │
│   ─────────────────────────────────────────────────────────────│
│                                                                 │
│   # Hello      →   <h1>Hello</h1>   →  {:defblock,  →  "<h1>   │
│   <.link>          <a href="...">       [...]}          Hello   │
│                                                         </h1>   │
│                                                         <a>.."  │
│                                                                 │
│   MDEx.to_html!    EEx.compile_string   Code.eval_quoted        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    Stored as HTML string
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         RUNTIME                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Phoenix.HTML.raw(html_string)  →  Rendered to browser         │
│                                                                 │
│   ⚡ Instant - no compilation needed                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Characteristics

| Aspect | Value |
|--------|-------|
| Performance | ⚡ Fastest |
| Phoenix components | ✅ Work (compiled at build time) |
| Dynamic assigns (`{@count}`) | ❌ Baked in at build time |
| LiveView bindings (`phx-click`) | ❌ Won't trigger events |

### Example Post

```markdown
---
title: "Getting Started with Elixir"
dynamic: false
---

# Welcome

Check out <.link href="https://elixir-lang.org">Elixir</.link> for more info.
```

The `<.link>` component is rendered to a plain `<a>` tag at build time.

---

## Dynamic Mode

**Best for:** Interactive posts with counters, forms, or live updates.

### How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                        BUILD TIME                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Markdown              HEEx HTML                AST            │
│   ─────────────────────────────────────────────────────────────│
│                                                                 │
│   # Counter        →   <h1>Counter</h1>     →  {:defblock,      │
│   {@count}             {@count}                 [...]}          │
│   <button              <button                                  │
│     phx-click>           phx-click>                             │
│                                                                 │
│   MDEx.to_html!        EEx.compile_string                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    Stored as AST (quoted expression)
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         RUNTIME                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Code.eval_quoted(ast, assigns: %{count: 5})                   │
│                              │                                  │
│                              ▼                                  │
│                   Phoenix.LiveView.Rendered                     │
│                              │                                  │
│                              ▼                                  │
│   Live updates when @count changes                              │
│                                                                 │
│   ⚡ Fast - only eval, no recompilation                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Characteristics

| Aspect | Value |
|--------|-------|
| Performance | ⚡ Fast (cached AST, no recompilation) |
| Phoenix components | ✅ Work |
| Dynamic assigns (`{@count}`) | ✅ Update live |
| LiveView bindings (`phx-click`) | ✅ Trigger events |

### Example Post

```markdown
---
title: "Interactive Demo"
dynamic: true
---

# Counter Demo

Current count: {@count}

<div class="flex gap-4">
  <button phx-click="dec">-</button>
  <button phx-click="inc">+</button>
</div>
```

The LiveView must define the event handlers:

```elixir
def handle_event("inc", _, socket) do
  {:noreply, assign(socket, count: socket.assigns.count + 1)}
end

def handle_event("dec", _, socket) do
  {:noreply, assign(socket, count: socket.assigns.count - 1)}
end
```

---

## Comparison

| | Static Mode | Dynamic Mode |
|---|-------------|--------------|
| **Frontmatter** | `dynamic: false` (or omit) | `dynamic: true` |
| **Stored as** | HTML string | Quoted AST |
| **Build time work** | Parse → Compile → Eval | Parse → Compile |
| **Runtime work** | Just output HTML | Eval AST with assigns |
| **Performance** | ⚡⚡⚡ Fastest | ⚡⚡ Fast |
| **Interactivity** | ❌ None | ✅ Full LiveView |
| **Use case** | Regular blog posts | Demos, tutorials, interactive content |

---

## Implementation Details

### Parser (`lib/event_horizon/blog/parser.ex`)

The parser checks the `dynamic` frontmatter key and returns either:

- `{:static, html_string}` - Pre-rendered HTML
- `{:dynamic, ast}` - Compiled AST for runtime evaluation

### Article (`lib/event_horizon/blog/article.ex`)

The `render/2` function handles both cases:

```elixir
# Dynamic: eval the cached AST with current assigns
def render(%__MODULE__{body: {:dynamic, ast}}, assigns) do
  {rendered, _} = Code.eval_quoted(ast, [assigns: assigns], __ENV__)
  rendered
end

# Static: just return the pre-rendered HTML
def render(%__MODULE__{body: {:static, html}}, _assigns) do
  Phoenix.HTML.raw(html)
end
```

### LiveView Usage

```elixir
def render(assigns) do
  ~H"""
  <div class="prose">
    {EventHorizon.Blog.Article.render(@post, assigns)}
  </div>
  """
end
```

---

## When to Use Each

### Use Static Mode When:

- Writing standard blog posts
- Content has no interactive elements
- Maximum performance is needed
- Using Phoenix components for styling only (like `<.link>`)

### Use Dynamic Mode When:

- Building interactive tutorials
- Including live demos (counters, forms, etc.)
- Content needs to react to user input
- Displaying real-time data in posts
