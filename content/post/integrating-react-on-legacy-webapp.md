---
title: "Integrating React with a legacy webapp stack"
cover: "/media/post/integrating-react-on-legacy-webapp/react_icon.png"
tags: ["frontend", "legacy", "react"]
date: 2019-01-10T21:37:14+01:00
draft: true
---

How to integrate React with a legacy webapp in an incremental manner, with minimal changes in the workflow.

<!--more-->

<!-- I should put here a header image of some screen with code or whatever -->
------------

## Context
A critical part of the web interface of a platform has lots of interaction. But all of it is implemented in jQuery, with event and callbacks everywhere, in pretty much a single javascript file containing the logic. Development speed has decreased a lot on that component, which is very problematic as it is a critical part of the platform and will need to evolve soon to include even more functionality. Something needs to be done.

## Solution
Rewrite that part in react, which will make the whole thing easier to reason about and easier to expand with new modules and components. Problem is that rewriting the whole thing in react is very expensive and there is already a strategy for asset management and compilation, which works fine for the rest. Changing the whole thing to use webpack would be expensive and prone to breakage. Ideally, what we would like to have is a system that actually preserves the current build system, but it able to work with newer tech, while being as close as possible to the development experience one would have with create-react-app.

So what we need is a way to write our components (in react) in ES6. Using the latest react syntax. Ideally with CSS modules and all. And then find a way to retrofit the whole thing so it will be compiled and minified using the legacy build platform. We would love to have CSS modules, and live reload and all that fancy stuff, but the basic things is: minify, work with latest syntax, easy to debug thanks to sourcemaps, CSS not being a mess.

We need to transpile code, minify it, add source maps. And something for the CSS stuff. Actually webassets offers us the tools, via babelify. It is not very clear, but it can be done with a little bit of ingenuity

Explain webassets config

Explain how it is actually setup in the project. In terms of JS, and SASS, and how it gets included in the templates.

Link to the actual sample project in GitHub.

Then dedicate a chapter to debug. Basically, the autobuild stuff, and the debug in browser stuff. Show what works and what does not. Explain the drawbacks compared to using create-react-app.

And finally go over a bit on what has been done, what has been achieved, what doesn't work. Basically the grand thing on this project is that we've been able to use all this new tools without touching a bit the webassets pipeline. So everything else: how the stuff is compiled, uploaded to S3, and the rest of the app, is just left as is, while that critical component that benefits most from a frontend framework can actually be developed that way comfortably without compromising the rest of the app. Basically, it's the best bang for your buck possible given the problem. And probably lots of apps could benefit from an approach like that when working on products that have been going for a bit and need an extra oomph.


## Pros and Cons

## Show features here

OUTLINE

- State the case. What is happening, what do we want
- why react and what can this bring. What would it solve?
- React drawbacks. What problems would it bring to add react to the project.
- what did we do?
- what constraints do we have? (basically, we can't start from scratch)
- Minimal changes but still we want to use modern tooling for that specific thing, and 
- Why do we choose such approach (adding react to an otherwise classic webapp)
- limitations? No auto reload, but F5 triggers the build anew, so it works well.
- You can use sourcemaps and navigate code, which is cool.
- Minification works fine

Recently I had to help out a client that needed some support for their frontend development. They had developed a chat editor for media corporations, to send highly targeted campaings to people that would be subscribed to their channels. Basically, spamming people.

They wanted to make it more interactive and basically add new features such as segmentation and targeting to the app, but the architecture of the app made it hard to implement changes. Also, bugs were difficult to locate, code was hard to test, it was easy to introduce regressions when fixing bugs, etc.

Basically the current app was a mix of backend-templating with a bunch of jQuery and CSS all intermingled together. State was scattered throughout the app and most of the workflow was a bunch of event listeners triggered at whim's. Very hard to wrap your head around what was going on.

Also important to note that there was already a strategy of javascript minimization and asset management, built on top of flask with webassets (also works with Django) that worked well for the rest of the app. Basically, when I speak about doing the photography of the app, I should mention that most of the app is an MVC template-backed with flask and Jinja, with some javascript interaction to spice things up, but simple for the most part. It is only in that part of the app that things get really complicated, although it is also true that most of the time users will be there, cause that is where you work, really.

So there is this twofold objective of coming up with a solution which is maintainable, integrates well with the current design (ideally, you don't want to break the workflow for the rest of the app because of this new thing you're adding, you just want to contain it)

The objectives were twofold: We had to implement a redesign of the look & feel of the app and basically we had to pay-off the debt of the current editor, by using something which would make it easier to continue evolving this critical part of the platform.

My solution went along the lines of, ok, let's write 

Recently I had this freelancing assignment. There was a jQuery project which had evolved in functionality and was complete spaghetthy. Hard to maintain. Impossible to reason about.

The idea was to take that part of the webapp and turn it into a React app, without changing the rest of the frontend stack. Basically a very selective operation, where we maintain the development workflow for the rest of the app and only really go for a modern JS framework where the extra functionality requires it.

The challenge was basically in integrating a new toolset, ES6, CSS modules and all that crap on the old app toolchain without breaking any of the other stuff but it still should have most of the features of modern development, with live reloading and all that crap.
