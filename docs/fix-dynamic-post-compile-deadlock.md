# Fix: Dynamic Blog Post Compilation Deadlock

## Problem

Adding a `<.poll />` component (or any LiveComponent wrapper) to a dynamic blog post caused the Elixir compiler to hang indefinitely with `beam.smp` at 100% CPU usage.

```markdown
<!-- This in a dynamic blog post caused the hang -->
<.poll id="ai-usage" type="yes_no" question="Do you use AI daily?" />
```

## Root Cause

The compilation pipeline for blog posts works like this:

1. `EventHorizon.Blog` uses `NimblePublisher`, which at **compile time** calls `Parser.parse/2` and `Article.build/3` for every markdown file
2. `Parser` compiles markdown → HTML → HEEx AST via `EEx.compile_string`
3. For dynamic posts, the compiled HEEx AST was stored directly in `blog.ex`'s module attributes

When a dynamic post contained `<.poll />`, the compiled AST embedded references to `EventHorizonWeb.BlogComponents.poll/1` and transitively to `EventHorizonWeb.BlogComponents.PollComponent`. The Elixir compiler detected these module references inside `blog.ex` and created compile-time dependencies, completing a circular dependency chain:

```
blog.ex (compile) → article.ex (compile) → parser.ex (compile)
  → blog_components.ex → poll_component.ex (export)
  → router.ex → blog_live/index.ex → blog.ex
```

This circular compile dependency caused a deadlock — the compiler waited for `PollComponent` to finish compiling, but `PollComponent` (through the router) waited for `blog.ex` to finish first.

The `<.counter />` component didn't trigger this because, while the same cycle existed, the compiler happened to resolve it in a viable order. Adding `<.poll />` (a new component in the cycle) tipped the balance.

## Fix

### Core change: store raw HTML instead of compiled AST (parser.ex)

Previously, `Parser` compiled HEEx at compile time and stored the AST:

```elixir
# Before
defp convert_body!(body, true = _dynamic?) do
  html_body = markdown_to_html!(body)
  ast = EEx.compile_string(html_body, ...)
  {:dynamic, ast}  # AST contains module references → compiler tracks them
end
```

Now it stores the raw HTML string. No module references, no compile-time dependencies:

```elixir
# After
defp convert_body!(body, true = _dynamic?) do
  html_body = markdown_to_html!(body)
  {:dynamic, html_body}  # Plain string → no module references
end
```

### Runtime compilation with caching (article.ex)

HEEx compilation now happens at runtime in `Article.render/2`, with the compiled AST cached in `:persistent_term` so it's only compiled once per VM lifetime:

```elixir
def render({:dynamic, html_body}, assigns) do
  ast = compile_heex(html_body)  # cached after first call
  {rendered, _} = Code.eval_quoted(ast, [assigns: assigns], __ENV__)
  rendered
end

defp compile_heex(html_body) do
  cache_key = {__MODULE__, :heex_cache, :erlang.phash2(html_body)}

  case :persistent_term.get(cache_key, nil) do
    nil ->
      ast = EEx.compile_string(html_body, ...)
      :persistent_term.put(cache_key, ast)
      ast
    ast ->
      ast
  end
end
```

### Simplified read minutes & TOC extraction (article.ex)

Since dynamic posts now store raw HTML (not an AST), `compute_read_minutes` and `extract_toc` can use the HTML string directly instead of needing AST walkers:

```elixir
# Before: needed Code.eval_quoted or AST walking
defp compute_read_minutes({:dynamic, ast}) do
  render({:dynamic, ast}, %{}) |> ...
end

# After: just reuse the static HTML path
defp compute_read_minutes({:dynamic, html_body}) do
  compute_read_minutes({:static, html_body})
end
```

### Removed BlogComponents from global html_helpers (event_horizon_web.ex)

`BlogComponents` was imported globally in `html_helpers`, meaning every LiveView and LiveComponent depended on it. This widened the compile cycle unnecessarily. Moved the import to only the modules that need it (`BlogLive.Index` and `BlogLive.Show`).

## Performance

| Metric | Before | After |
|--------|--------|-------|
| Compile time | Hangs indefinitely | Normal |
| First render (cold) | 0ms (pre-compiled) | ~50ms (one-time compile + cache) |
| Subsequent renders | ~8.5ms | ~8.5ms (same `Code.eval_quoted` cost) |

The `Code.eval_quoted` cost per render (~8.5ms) is identical — it existed before too. The only new cost is a one-time ~50ms HEEx compilation on the first request, cached for the VM lifetime via `:persistent_term`.

## Files Changed

- `lib/event_horizon/blog/parser.ex` — store raw HTML for dynamic posts
- `lib/event_horizon/blog/article.ex` — runtime HEEx compilation with caching
- `lib/event_horizon_web.ex` — remove BlogComponents from global imports
- `lib/event_horizon_web/live/blog_live/index.ex` — add BlogComponents import
- `lib/event_horizon_web/live/blog_live/show.ex` — add BlogComponents import
