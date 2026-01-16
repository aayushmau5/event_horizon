---
title: "My custom MDX components"
description: "Custom MDX components that I use in my blogs"
date: 2022-02-18T11:00:39.972Z
tags: ["mdx"]
draft: false
showToc: true
dynamic: true
---

# Callout

> (info) **Info** Callout

> (danger) Danger Callout

<.counter id="counter" />

# Cards

## Random Cards

### Third

#### Fourth

##### Fifth

###### Sixth


> (card) Hello, world

> (card: "This is a title") In a card with title

> man this is (pretty cool) in a way

- This is an ol
- This is another ol

1. Hello World
2. Goodbye world

# Code blocks

```js
console.log("Hello, world!");
```

```
Block without language
```

```ts filename="wrong-catch.ts"
useQuery(["todos"], () =>
  axios
    .get("/todos")
    .them((response) => response.data)
    .catch((error) => {
      // returns a resolved Promise
      console.log(error);
    })
);
```

```elixir filename="text.ex"
def Hello do
  {:ok, System.get("lol")}
end
```

```css filename="something.css"
body {
  color: white;
}
```

```html filename="something-else.html"
<h1>Hello world</h1>
```

`inline code`

# Aside

> This is an aside

# Anchor

[My Github](https://github.com/aayushmau5)

# HR

---

# Hidden expand

> (details: "Summary")
> Hidden until expanded
>
> More lines
> **With** markdown
> - let's see
> - if this works
