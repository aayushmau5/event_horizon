---
title: "Unemployment log 001"
description: "What have I been up to these days?"
date: 2026-07-14T00:20:55.161757Z
tags: ["life", "elixir"]
cover:
  image: "/images/blog/unemployment-log-001.jpeg"
  alt: "Mountains"
  caption: "Life is good!"
draft: false
showToc: false
dynamic: false
---

It has been 20 days since I was [laid off](/blog/layoffs). 

So, what have I been upto?

Honestly, at this current stage, I feel fine. These 20 days went away like a breeze. I'm treating this period as the holy grail of "what not having a job feels like initially".

I'm slowly picking up my hobbies: reading, programming, going out. Though most of my time is going into programming. My lleep cycle is worse than ever.

Though I'm actively looking for a job, so far, nothing substantial has come up yet. So it's only my hobbies, my partner and my cat that are keeping me sane.

Let's talk about the thing that has been consuming most of my time.

# Eva

I'm working on [Eva](https://github.com/aayushmau5/eva) (inspired by Neon Genesis Evangelion). It's an AI agent coding harness that's written in Elixir. I have been building it for a while now. In fact, I'm obsessed with it. Either I'm building the thing or thinking about what more to build. I'm clocking at 10-12 hours of just working on Eva.

> An agent harness is basically the scaffolding that turns raw LLM output into actual working code changes.

I have been curious about Agent harness ever since I read [this blog by amp](https://ampcode.com/notes/how-to-build-an-agent) folks. "How do we go from API responses from agents to spitting out (slop) code?". So I rolled up my sleeves, and got to work. I have been learning about [pi](https://pi.dev/), & [tau](https://twotimespi.dev/) and its architecture, its plugin system, storage, tool calls, subagents, etc.

Around 80-90% of the code is handwritten, and I love it. There's something deeply gratifying about thinking about systems, brainstorming architectural ideas, making the building blocks and then fitting them together. Yeah, I love programming!

That's not to say I don't use AI. In fact, I think I have found a balance between AI and me. I have a clearer picture of what things to delegate to AI, how to brainstorm and question its intent, coming up with acceptable code.

Btw I'm using OpenCode and my go-to models are DeepSeek V4 pro & GLM 5.2.

Anyway, I just finished v0 of Eva (with Web UI built in LiveView). This is running locally on LMStudio and Nvidia's Nemotron 3 4B cause my M2 Macbook Air with 8gigs of RAM can only handle that much ;-;

Here's a demo:

<video src="/videos/Eva_v0.mp4" controls width="100%"></video>
*Eva V0*

It's still missing a lot of features, and I have some [ambitious plans](https://github.com/aayushmau5/eva#feature-checklist) for Eva.

Twenty days in, and honestly, Eva's been the best thing to distract my jobless brain. More on Eva soon, and hopefully some job-hunt updates(or are we waiting for "Unemployment log 002"?)

Time to get back to building. See you on the next one!
