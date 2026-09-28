---
title: "Unemployment log 002"
description: "Life update"
date: 2026-09-17T18:41:37.110440Z
tags: ["life"]
draft: false
showToc: false
dynamic: false
---

Hello World! It's [been a while](/blog/unemployment-log-1).

Welcome to yet another unemployment log. Well, I got a job, but I will wait a while before making an announcement. The reason you will read now...

# What a market

The job market has substantially changed since last year. Everyone expects you to be a "kickass 10000x developer who has built something of their own"(*slight exaggeration*).

I have interviewed for the following roles so far:

1. AI Harness Engineer
2. Product Engineer
3. Member of Technical Staff
4. SDE-2/3

Of course, AI has been common among all of them. How do I use AI? How have I leveraged AI in my personal life? Have I built and launched a product of my own using AI?

All this bullshit only to end up prompting Claude/Codex all day.

I mean, sure, I'm doing what most folks expect me to do. I'm a **Software Architect**. I do the research, build up the context about the product, understand the problem, come up with potential solutions, brainstorm with AI, and then let AI execute the plan. I try to keep it under control, which honestly feels like swimming against the wave. I don't even review all the code personally anymore; I review it through a bunch of other AI tools. Write -> Review -> Fix. Repeat.

It is frustrating, but that's the reality I guess.

Another thing is these startups are craaaazy. I really don't like the AI race we are in right now, honestly. "You gotta have velocity when people can clone your product overnight."

There's also this new trend of work trials: "Come work for us for a week/month so we can evaluate you." Then there are **six-day working weeks** at some Bangalore-based startups. Man, it is bad out there. So I guess I'm lucky enough to have landed something.

The reason I'm not saying that I'm employed yet is because I am on a paid work trial. They can decide not to continue with me if I don't perform well :shrug:. Oh btw, there is a three-month probation after the work trial. Eh...

# Some fun

Well, ever since I started working, I haven't had much time to work on [Eva](/blog/eva-harness). But I do want to share some things I worked on during the past few weeks.

## Eva Extensions

Eva is a coding harness I have been writing in Elixir. I landed support for extensions in Eva.

So far, Eva has the following extensions, most of which I vibe-coded using Codex:

1. Worklog: Let an agent write ticket-based worklogs. What you worked on, how long, etc.
2. Logger: Event and transcript logging.
3. MCP: MCP as an extension (I use this for Exa web search).
4. Memory: Cross-session, vector-based memory for storing facts and explicit memories.
5. Mobile: A mobile app that works as an Eva extension.
6. Desktop: An extension for controlling the desktop.
7. Artifacts: HTML, Markdown and PDF artifacts + agent combination.

The fun part is that these extensions don't have to live on the same machine as Eva. I use distributed Erlang nodes over Tailscale, with Eva acting as the hub and extension nodes connecting as spokes. An extension can run pretty much anywhere. Right now, I have an OCI instance, my MacBook, and an old Dell Inspiron laptop all running Eva extensions and talking to each other. My own tiny distributed system hehe.

I'll deep dive into the whole thing in a technical post someday.

## Bnana

I also made an iOS app in Elixir. Because why not?

It is called [Bnana](https://github.com/aayushmau5/bnana) (the name has no story, I just couldn't think of anything better). It started as an experiment to see if I could write an iOS app in Elixir using [Mob](https://mobframework.com/).

Then, with the help of AI, I was able to do a lot more with it. It slowly became a collection of small problems I wanted to solve for myself. The primary user is only me. It is open-source, but I don't really plan on turning it into a product for everyone.

The app describes itself as:

> a small place for you :)

That is pretty much what it is.

### Writing on the go

The first feature was a blog editor. I wanted to write drafts whenever an idea came to me instead of waiting until I was back at my laptop. In fact, parts of this very blog were written inside Bnana.

It also connects to this website through a Phoenix Channel. I can look at analytics, read comments and contact messages, manage notes, and access some other small tools from my phone. There is an iOS widget sitting on my home screen that shows how many visits my website has had that day.

Do I need live website analytics on my home screen? Probably not. Is it cool? Yes.

### Small days, kept gently

Bnana also has a Memory Book. I didn't like the UX of the existing apps I tried, and making my own gave it a more personal touch.

It is not meant to be a serious journaling system. I usually add small logs like "Good weather today" with a photo I took, or something I am going through at the time. One sentence is enough.

Then there is "Last time". It keeps track of regular things that I somehow forget the last occurrence of. When did I last water my plants? When did I last go on a date? Things like that. It also has a widget, so I can mark something as done without opening the app.

### Saved links + Eva

The saved-links feature has been particularly useful. I added a "Save to Bnana" shortcut on iOS, so whenever I find an article I want to read, I can send it straight to the app.

My problem is that I like reading articles, but I lose the trail after a while. I save them and then forget why I was interested in them in the first place.

I also don't like AI summaries of articles. A summary tries to replace the original. I want something that makes me want to read the original.

So each saved link has an "Incentives" page. Bnana sends the link to an Eva extension running on my OCI instance. Eva Web is running there too, and the extension exposes an API endpoint for "reasons to read". It can start an Eva session, call a model, go through the page, and return a list of things I might get out of reading it.

Not a summary. Just: "Here is why this may be worth your time."

I love that Bnana and Eva work together like this. It is exactly the kind of weirdly specific personal software I wanted to make.

### Elixir on iOS

Mob is still in its early days, but it is quite promising. I love the fact that most of the app is written in Elixir. Some iOS-specific things still need Swift, Objective-C or C, and frankly I didn't understand those parts at all. I let an agent handle them.

There are also some gaps right now, like proper access to secure storage. But I have the app installed on my phone, I actually use it, and it has native widgets. That is pretty cool for something that started with "Can I make an iOS app in Elixir?"

I know what I wrote earlier about AI making engineering frustrating. So what's different here?

I enjoy the process of building **with** AI. I use it as a tool. The ideas, architecture, UI decisions and testing are still in my head and under my control. Most of the code in Bnana was written by AI, but I decided what the app should be and kept testing it on my phone until it worked the way I wanted.

The job version expects a lot more responsibility while also forcing me to get things done **by** AI. The goal becomes output and velocity. That feels very different from using it at my own pace to explore an idea.

# Epilogue

Eva and Bnana have been keeping me sane. I keep learning new things while building them.

Building Eva made it much easier for me to look at other harnesses and understand how they might be working under the hood. It also helped me during interviews. More importantly, it made me realise that I enjoy building things around AI: putting it in places where it wasn't before, or building systems that help it do more.

As for the job, I am still on the work trial. Maybe this is the end of the unemployment logs. Maybe it isn't.

Let's see how it goes.
