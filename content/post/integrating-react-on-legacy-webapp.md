---
title: "Integrating React with a legacy webapp stack"
author: "Octavi Font"
cover: "/media/post/integrating-react-on-legacy-webapp/react_icon.png"
tags: ["frontend", "legacy", "react"]
date: 2019-01-10T21:37:14+01:00
draft: true
---

How to integrate React with a legacy webapp in an incremental manner, with minimal changes in the workflow.

<!--more-->

Recently I had this freelancing assignment. There was a jQuery project which had evolved in functionality and was complete spaghetthy. Hard to maintain. Impossible to reason about.

The idea was to take that part of the webapp and turn it into a React app, without changing the rest of the frontend stack. Basically a very selective operation, where we maintain the development workflow for the rest of the app and only really go for a modern JS framework where the extra functionality requires it.

The challenge was basically in integrating a new toolset, ES6, CSS modules and all that crap on the old app toolchain without breaking any of the other stuff but it still should have most of the features of modern development, with live reloading and all that crap.
