---
title: "Moving my website from NextJS to Phoenix"
description: "My journey of moving from NextJS to Phoenix"
date: 2026-01-27T00:00:00.0Z
tags: ["elixir", "phoenix", "liveview", "mdex", "nextjs"]
cover:
  image: "/images/blog/nextjs-to-phoenix.png"
  alt: "Move to Phoenix"
  caption: "Logos are trademarks of their respective owners: Next.js (Vercel), Phoenix Framework, Elixir, Fly.io and Amp"
draft: false
showToc: true
dynamic: true
---

# Intro

Hello world! Welcome to my website which is now powered by Phoenix & LiveView. I took the decision to move it from NextJS to Phoenix around 2 weeks ago(Jan 14). This is a story about the journey I went through while moving stuff from NextJS to Phoenix, facing some hiccups along the way, overcoming them, some AI stuff & a fun interactive demo at last :)

Buckle up. Here we go!

# Reason for move

My journey began with the release of [MDEx](https://mdelixir.dev/) v0.11.0, which added support for Phoenix HEEX components in markdown. Previously, I used MDX in my NextJS app for embedding React components in markdown. With MDEx, I saw a way to move my custom MDX elements to Phoenix component equivalents.

And honestly, I didn't need much convincing. I've been an Elixir fan for ~4 years now. The language and runtime are just _magical_ ✨. I love the ecosystem—Phoenix, LiveView, Livebook, FLAME, JidoAI—and I've built [some](https://phoenix.aayushsahu.com) [stuff](https://battleship.aayushsahu.com) with it myself.

> BEAM is still ahead of the curve. Processes, supervision trees, message passing, distribution—these fit naturally into modern architecture patterns. Agent orchestration frameworks like [Agent Jido](https://agentjido.xyz/) are a great example.

The code is [here](https://github.com/aayushmau5/event_horizon).

# My journey

I started with a prototype. I wanted to see how far MDEx can support my needs. I started with [`nimble_publisher`](https://hexdocs.pm/nimble_publisher/index.html) as a filesystem-based publisher which very conveniently allows you to provide a custom parser for markdown files. I created a custom parser with MDEx.

My existing MDX blogs had a bunch of different components in them. For example, here's an example of a callout component:

```md
<Callout type="info">
    This is a callout component
</Callout>
```

Which looked like:

> (info) This is a callout component

And I can't just use this as it is. What I can do is create a phoenix component out of it.

```elixir
def callout(assigns) do
  ~H"""
  <div class="callout">
  ....
  </div>
  """
end
```

And use it as:

```md
<.callout type="info">
  ...
</.callout>
```

But I quickly ran into a [problem](https://elixirforum.com/t/liveview-mdex-how-do-i-use-phoenix-components-in-render-function/73961). But with a lot of back and forth with the creator of MDEx [Leandro Pereira](https://leandro.io/), I was able to get somewhere. We ended up finding an issue in MDEx parser itself.

> Leandro was very helpful in getting the prototype done. If you are using MDEx in your projects, consider [sponsoring his work](https://github.com/sponsors/leandrocp) :)

FYI: If you are in the same boat as me, `MDEx v0.11.1` has good support for Phoenix HEEX components.

## Using MDEx

Even though I was able to use Phoenix Components for my custom elements in markdown, I wanted to go a bit more conventional. I wanted to cleanup the usage of these components from markdown itself, and make use of them during compilation.

For example, the same callout component, I'd rather combine it with blockquote with some special variable to make it as a callout.

```md
<Callout type="info">
    ...
</Callout>

Can be converted to

> (info) ...
```

> (card) Github does something like this
> ```
> > [!NOTE]
> > Useful information that users should know, even when skimming content.
> ```

Luckily, Leandro has thought about this as well. MDEx provides the ability to `traverse_and_update` the processed markdown documents. 

Here's how I wrap the links in markdown with a custom `<.styled_anchor />` component.

```elixir
defp transform_node(%MDEx.Link{url: url, nodes: nodes}),
  do: %MDEx.HtmlInline{
    literal:
      ~s(<.styled_anchor href="#{escape_attr(url)}">#{render_nodes(nodes)}</.styled_anchor>)
  }
```

Rest of the code [here](https://github.com/aayushmau5/event_horizon/blob/0fa7af0/lib/event_horizon/blog/mdex_plugin.ex). **Note:** MDEx provides support for heex components inside markdown out of the box but my requirements were different.

### Dynamic & Static markdown

With `nimble_publisher` & MDEx, I was able to move all of my blogs here. All the blogs are stored as parsed html at build time, and it's pretty fast to show them.

Phoenix LiveView allows me to build real-time server driven UIs, so _of course_ I had to find a way to use these UIs in my blogs. Introducing "dynamic" blogs.

Suppose I want a "Counter" component with + & - buttons.

```elixir
def MyApp.CounterComponent do
  use MyApp, :live_component
  
  def mount(socket) do
    {:ok, assign(socket, count: 0)}
  end
  
  def handle_event("inc", _, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end
  
  def handle_event("dec", _, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end
  
  def render(assigns) do
    ~H"""
    <div>
      <div>{@count}</div>
      <button
        phx-click="dec"
        phx-target={@myself}
      >
        -
      </button>
      <button
        phx-click="inc"
        phx-target={@myself}
      >
        +
      </button>
    </div>
    """
  end
end
```

I can just drop it in my blog and use it as it is. All driven by liveview.

```md
# Hello Markdown

Here's a counter:

<.counter id="counter" />
```

<.counter id="phx-to-next-counter" />

Pretty neat!

## Adding Real-time features

My NextJS website had some real time features such as currently online people count, website visits, number of people reading a blog, blog visits. All updated in real-time. More on this [here](https://aayushsahu.com/blog/nextjs-phoenix-channels). It was implemented using Phoenix channels, & PubSub. It was part of another phoenix app I have running on fly.io

Since this is an elixir app, and will be hosted on fly.io, I figured instead of going with Channels, I would cluster these two elixir nodes, and use PubSub for communication.

All it boils down to:

- You have a `Phoenix.PubSub` process running on both nodes under the same name.
- `Phoenix.PubSub` supports distribution out of the box
- That's it!

I can publish a message from one node and handle it on another.

```elixir
# Node 1
def mount(_params, _session, socket) do
  if connected?(socket) do
    PubSub.subscribe(Common.PubSub, "analytics:blog:visit") # To get blog visit events
    PubSub.publish(Common.PubSub, "blog:visit") # To send a blog visit to update the visit count
  end
  
  {:ok, socket}
end

def handle_info({:blog_stats, ...}, socket) do
  {:noreply, assign(socket, blog_visit: ...)}
end

# Node 2
PubSub.publish(Common.PubSub, "analytics:blog:visit", {:blog_stats, ...})
```

### PubSub contract

Honestly, I had a lot of PubSub `subscribe` and `publish` going on in my app, and it was getting hard to form a mental model of where processes are subscribing to a topic, and which processes need to handle the message and how. So I created a personal library to make it more streamlined. For example, for blog visits, I have `%Blog.Visit{count: ...}` struct for blog visits, `%Web.Visit{count: ...}`, `%Blog.Comment{author: ..., comment: ...}`, etc. I named it `pub_sub_contract`. It's on [github](https://github.com/aayushmau5/PubSubContract). I haven't published it as a package because it's for my specific use case. You can check it out and reach out to me if you need something like this.

## Some goodies

At this point, the core migration was done—blogs rendering, real-time features working. I hosted it on [fly.io](https://fly.io) and it's working quite well! But I also rebuilt a few nice-to-haves from my old site.

### Adding Command bar

One cool thing I had with my NextJS blog was a command bar using the [Kbar](https://kbar.vercel.app) library. I had to create one from scratch. I was looking at some off the shelf libraries, but ultimately decided to just take help from [amp](https://ampcode.com/). Code lives [here](https://github.com/aayushmau5/event_horizon/blob/be74a52/lib/event_horizon_web/components/command_bar.ex).

### Blog image generation

For blog banner images, I previously relied on Cloudinary to create banner images on the fly. The banner image consists of a static background with the blog's title on top.

I didn't want to rely on Cloudinary anymore. So using elixir's [image](https://github.com/elixir-image/image) library, I created a mix task which would go through all my blogs, and create an image using the title. It's fast and not relying on any external service!

### Mix tasks

Had some common mix tasks as part of "setup" process: Creating [RSS feeds](https://aayush-event-horizon.fly.dev/rss.xml), generating sitemaps, image generation. Love it!

# Clustering

I have three elixir apps currently deployed on fly.io. One is this phoenix app, second is another phoenix app that I made that contains a set of personal tools that I use in my day-to-day life, and third is a battleship game that I created during my initial phase of learning elixir & phoenix.

These are deployed in the Amsterdam, Paris & Mumbai regions. One awesome thing about fly.io is that they provide cross-region internal networking across apps in an organisation. As a plan to have some real-time metrics in the website, I clustered this app with the second one. I just went ahead and clustered all these applications. Haven't had any nodes go down on me yet.

There's a [cluster page](https://aayushsahu.com/cluster) where you can see the latency measurement between all three apps, along with your latency with the website. Powered by some `:erpc` calls and PubSub. Neat!

# Using AI

Throughout this journey, I made pretty heavy usage of AI agents such as: [amp](https://ampcode.com/), [tidewave](https://tidewave.ai/) with Github Copilot, [Cursor agent CLI](https://cursor.com/cli), [Opencode](https://opencode.ai/).

Agents helped me with:

- Moving existing react components to phoenix ones
- Creating Command bar from scratch
- Clustering stuff
- A lot of MDEx code
- Creating the `pub_sub_contract` lib
- Working across codebases to consult the original website while making changes in the new one

Out of all these tools, I used amp primarily. Amp is so good. In fact, it was the best at writing elixir code out of all. Its subagents like `librarian` & `oracle` enabled the `smart` agent(Claude Opus 4.5) to write pretty good elixir code. It even helped me out with MDEx. The librarian would check out the docs, the code on github, and with oracle come up with a pretty good plan.

## My view

My view on AI is of a love-hate. Sometimes it performs amazingly, and I love it. And sometimes, it writes error-prone code and I declare "THEY AREN'T TAKING OVER THE WORLD YET" xD

Honestly, I got a lot of work done in much less time with their help. But then came feelings of not knowing what it's doing exactly. Does anyone relate?

I love writing code and learning new things about systems I work with. It would've taken me much longer to build the command bar myself, figure out clustering rules, and configure MDEx. But would that have been worth it? I'm torn. Part of me says "Yes, it would've been more fun." Another part says "You got shit done sooner!"

Right now, some people are pondering upon the question: "Should we even look at the code?" 
I'm not sure. I have always felt writing code is an art, a garden piece where you plant trees/flowers/plants, and **you take care of them**. It's something you have to be able to enjoy. Doing stuff with agents helped me plant those trees faster, but will they be there when I need to take care of them? I am more leaning towards "yes", but some part of me says we would still need to be there, present in the code.

The breakneck speed of stuff coming out is certainly interesting. While agents are solving existing problems, we now have a set of new problems arising to deal with(code reviews, lazily evaluating the code which ends up breaking things on prod, etc.). Would be interesting to see the new solutions people are coming up to tackle these problems. Certainly a good time to get involved :)

We'll see how things go. One thing I'm certainly keeping in mind: "Be able to let go of your opinions on stuff. These things can surprise you a lot, both in a good way & bad".

# Outro

That concludes my journey on moving my website from NextJS to Phoenix. It was a lot of fun, learnt a lot of new & cool things working with Phoenix. Still very much in love with Elixir & BEAM :)

# Fun thing

As an end to this, I have created a fun interactive poll. Powered by LiveView and clustered app. It's silly. Have fun!

<%= live_render(@socket, EventHorizonWeb.BlogComponents.Poll, id: "phx-vs-next-poll") %>
