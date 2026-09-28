---
title: "IndiaFOSS 2026"
description: "My experience at IndiaFOSS 2026"
date: 2026-09-28T08:05:46.685244Z
tags: ["open source"]
draft: false
showToc: false
dynamic: false
---

IndiaFOSS describes itself as
> one of the largest gatherings for the country's Free and Open Source Software communities. Less of a classical conference, more of a festival for FOSS, digital commons and all the people who make it happen!

The conference took place on 26th-27th Sept. in Bangalore. I attended both days, and yeah, the festival part checks out.

When I first went in, my immediate thought was: "Should I just go back home?"

There was an immense crowd, a lot of noise, and pretty much every booth was packed. It was a sensory overload. I couldn't decide where to go or who to talk to. My introvert ass was ready to call it a day.

But then I just picked a booth and struck up a conversation.

That booth was Gooey.AI. They are building an agent orchestrator with a bunch of things pre-configured out of the box. Want a Whisper flow in your agent? It is a setting away. Want to run LLMs locally or on the cloud? You can do that too.

I got interested because I have been building my own agent harness in Elixir called [Eva](/blog/eva-harness). I didn't walk away with some life-changing insight about harnesses. If anything, I was reminded that they are still a complex beast. But I did leave with a question: "How can I make Eva more powerful?"

That was enough. I had stopped thinking about going home.

## Why attend?

I have been, for most of my tinkering-with-computers era, an open-source guy. I believe everything should be open-source (I am safely ignoring the monetary aspects of it for now).

I got introduced to Open-Source during my first year in college (2019) through the Open-Source community there. The first thing that got me was the passion with which everyone talked about it. There was something genuinely human about people caring so much, doing things in the open, helping each other, and building things simply because they wanted to.

I started tinkering with Linux-based distros, ricing my setup, breaking things and fixing them. It was a lot of fun. There's so many creative things going on in the world!

But for most of my professional software engineering career, I have worked in closed-source environments. Building products for customers, generating revenue, the usual stuff. It pays and it is okay. But between a full-time job and normal life, I slowly stopped building as much. I didn't have the time to contribute through code or community. My belief in Open-Source didn't change, but my ties with it got rusty.

By the time IndiaFOSS came around, I wasn't particularly keen on attending. I couldn't recall that enthusiasm, creativity and fun part of OSS anymore. But with some nudging by my friends, I finally went.

## The people part

Once I got through that first conversation, I started talking to more people around the booths. What were they building? Why did they pick this problem? Why did they choose to make it open-source?

That's when the OSS ethos started coming back to me. It was not only that the products were open-source. A lot of them put people first in some way: privacy, ownership, choice, preservation, or sometimes just the freedom to create something out of curiosity.

> There was just something beautiful to see a bunch of cool nerds just coming together and doing things they wanted to do.

## Booths

Let's talk about some of the booths. There were a lot of them, and a lot of them were cool af.

### tangled.org

Tangled is a new social coding platform (think GitHub alternative). It is built on AT Protocol and has a pretty unique architecture.

Their Git servers are called "knots", and they speak a PDS-like protocol. The way I understood it, the PDS puts out events which Tangled consumes through the firehose. Then there is "Bobbin", a storage-less, in-memory graph database that provides a highly scalable representation for the UI to consume. They also have their own CI infrastructure called "Spindle".

The knot servers can live anywhere. A user can self-host one and still be part of the wider community. The UI was also very snappy.

The Tangled folks were more than happy to explain how all of this fits together and what they are planning for the future. I loved the technical novelty of it. There are so many new things for me to learn, and I am always curious about how people make these systems work.

I want to contribute to Tangled, though realistically it will have to wait until I have more time.

### p5.js community

I have always been interested in generative coding. I have explored making shapes and art through code using p5.js & WebGL, and making music through Sonic Pi or Strudel. My hiccup has always been the first step: the approach. I know I want to make something, but not how to start. I have picked up and left p5.js and Sonic Pi at least five times in the last three years.

There was a community at IndiaFOSS specifically interested in this space. They showcased a bunch of really cool art and some Strudel beats. When I talked about my struggle with getting started, they could relate. What worked for them was attending meetups and just hanging out with the community. Seeing other people create things pushes you and inspires you to get back to it.

I felt heard, honestly. Maybe what I lacked wasn't interest. Maybe I was just trying to do it alone. They have a meetup soon, and I plan on attending :)

### Bruno

Bruno is an open-source, no-fluff, fully offline API client. Think Postman, but OSS and good.

I talked to the folks about their business, and I was genuinely surprised to learn how many paid customers they have. In my years of working, I have barely seen anyone use an API client other than Postman. The industry just defaults to it, so I wasn't expecting Bruno to have such a good user base.

Turns out, "industry standard" doesn't mean everyone is happy with it. People are looking for genuinely useful and better alternatives, and they are willing to pay for them. It was good to see that people do give a shit.

### Tiles and Solstone

Tiles is an open-source, local and private AI harness. It uses AT Protocol and Iroh to provide a sync layer, chat sharing, remote inference, and a bunch of other stuff. One of my closest friends has been contributing to Tiles for a while and is now its CTO (yayyy!).

I attended a Tiles 🤝 Solstone testing session where we spun up both projects locally and looked for UI, UX and operational issues. It was a bunch of us sitting with both teams and testing things together. Open-source software being worked on in the open. Fun!

Seeing my friend do all this also made me happy. More than that, it made being part of open source feel possible for me again. I can do something similar. I can be part of a community and build things I care about.

### And a bunch more...

- Ente is an open-source alternative to Google Photos.
- OpenSpeaks works on tools for documenting and archiving endangered languages. I missed the chance to speak with them at the conference, but I have reached out async. I have been volunteering on a project in a similar space, so let's see if anything comes out of that.
- 4th Cross Labs houses a bunch of open-source projects with a focus on simplicity (single-binary installations, non-slop code, etc.). Love it.
- There were people working on fully local and private digital health apps, open-source healthcare, data visualisations, data for India and much more.

I also had a brief conversation with someone from BharatDigital. One point they made stayed with me: knowing that a social problem exists is not enough. If you want to understand whether a government scheme has problems, try helping someone sign up for it. See where they get stuck, how the people involved respond and what happens outside the neat flow you imagined.

The real world is more complicated, and people and systems can be unwilling to change. You understand the actual issue by getting your hands dirty, not just by building a pothole tracker or another dashboard.

It also made me want to eventually visit Kinnaur and see how the thing I am volunteering on is actually being used. Is it even helping? Good question to answer.

## Talks & Discussions

Then came the talks and panel discussions. I couldn't attend many because I was busy talking to people outside haha.

I managed to attend "Tracking-free and hackable network cameras", "Building OpenSpeaks tools for language documentation and archiving", "Tiles: Own your AI with open models and decentralized protocols", and some devroom sessions on making music and exploring music hardware.

The one discussion I kept thinking about was "The future of FOSS, SWE and Technical Education".

### AI

Each panelist described how AI had changed their field of work, the surprising things they were seeing, and how one could use it in open source or at work. It was refreshing to hear a sane take on AI. Yes, it can be a performance booster. There is also a lot of slop being put into the market every day.

My takeaways were:

1. There is a lot of opportunity in bringing AI to non-tech industries where it can provide genuine assistance.
2. The ceiling has risen. Writing the code is no longer the whole job. You now have a bigger responsibility towards the product you are building and the people using it.
3. You can have more leverage, authority and opportunity when working on something.
4. You have to sift through everything and find your own path: "messy jobs, wicked problems and interdisciplinary learning".
5. Keep going back to first principles. Ask, "Does this problem even need a technical solution?"

Right now, the most obvious thing people are doing is trying to extract more money from the AI economy. Things are volatile and changing fast, so the uncertainty around it is only human. We haven't fully grasped the change AI is bringing to our lives. There is still a lot to figure out.

But this discussion gave me a certain sense of calmness. AI can also make things better. I don't have to be in a race to build the next million-dollar business. I can use the extra leverage to create more impact, help people, and work with a community. That feels a lot more human to me.

## So, what changed?

I walked into IndiaFOSS feeling overwhelmed and thinking about going home. I walked out feeling motivated to work on things, and hopeful about the future (both mine and the world's).

I have always wondered how I can use my skills for the betterment of the world. But circumstances, or just the normal path of life, put me in corporate jobs building products. That pays and it is okay. Still, the feeling that I could do more has always stayed.

This conference reminded me that I have to be proactive about it. It also showed me where I can find the right people to work with.

Seeing people build better alternatives, care about privacy and ownership, preserve languages, and make art just because they are curious made me feel hopeful. The outright curiosity of some of the younger folks reminded me of the vigour I used to have when I first got into all of this.

The conference itself was difficult to navigate. There was too much happening, and I was trying to put all of it on my plate. But honestly, I am not sure I would do anything differently. It was still fruitful. If anything, I would have even more personal conversations and discussions with the people around me.

## What's next for me?

Fresh off the conference, I have fuelled up to continue or start working on a few things:

1. **Continue volunteering:** During the time I was unemployed, I started volunteering for Zed.tells. I am creating an interactive and community-driven dictionary/archive for an endangered language from Kinnaur. I have already started this work, so it is my first priority. Hopefully, I will have something tangible enough to give a talk about at IndiaFOSS 2027.

2. **Get back into generative coding:** I have a community meetup to attend soon. This time, maybe I won't try to do it alone.

3. **Contribute to Tangled:** I really loved Tangled from a technical perspective. There are a lot of new things to learn there. I am not sure where to start yet, and with a full-time job my time is limited. I will get to it after making progress on Zed.tells. The fire is there, though.

Overall, this was a really cool conference. I met a bunch of cool people, rediscovered a part of myself that had gotten rusty, and left wanting to do more.

See you on the next one :)
