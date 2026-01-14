---
title: "Hello World"
description: "This is a nice description"
dynamic: true
cover:
    image: "/public/blogImage.jpeg"
---

# Hello World
```elixir
IO.puts("hello world")
```

# Demo

Hello from MDEx :wave:

**Markdown** and **HEEx** together!

Today is _{Calendar.strftime(DateTime.utc_now(), "%B %d, %Y")}_

---

<div class="flex items-center gap-4 p-6 bg-white/10 rounded-xl my-6 not-prose">
  <div>{@count}</div>
  <button phx-click="dec" class="w-10 h-10 rounded-full bg-red-500 text-white text-xl font-bold">-</button>
  <button phx-click="inc" class="w-10 h-10 rounded-full bg-green-500 text-white text-xl font-bold">+</button>
</div>


---

Built with:
- <.link href="https://crates.io/crates/comrak">comrak</.link>
- <.link href="https://hex.pm/packages/mdex">MDEx</.link>
- <.link href="https://hex.pm/packages/mdex">MDEx</.link>

```elixir
:erlang.link()
```
