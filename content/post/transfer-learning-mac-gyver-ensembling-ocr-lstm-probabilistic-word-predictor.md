---
title: "Transfer learning, the MacGyver's way: Ensembling an OCR LSTM model with a probabilistic word predictor"
date: 2019-05-23T14:18:01+02:00
draft: true
---

How can you improve the performance of an OCR LSTM model when applied to a setting it wasn't trained on? Is it absolutely necessary to kick-off a data collection effort and use transfer learning to retrain the network? This is how I improved accuracy on the cheap by ensembling the original model with a custom-made probabilistic word predictor.

<!--more-->

This story starts as part of a processes optimization project I'm conducting with a client. They wanted to develop some in-house technology to scan IDs automatically to speed up their enrollment process.

To solve this issue, I had to develop a whole OCR pipeline, with preprocessing of the image, segmentation, deskew and OCR of the document. ID cards and passports come in many shapes and forms. Even within the same country, there are different versions and variations, which makes this a hard problem to solve, especially on a shoestring budget.

Fortunately, most new state issued id cards and passports have a machine readable zone, containing most of the id information in a format prepared for OCR. MRZ is a standard (ISO xxxx) introduced in the 1980s that has seen wide deployment throghout. Try to put some more info about the current usage and deployment of this technology. Nowadays, most id cards also have an RFID chip for biometrics, which is what people use in the ePassport gates.

Now that I've explained that the MRZ is a standard, and that mostly DNI, NIE and passports have it, and also that it contains most of the information that the client needed for identification purposes, say that OK, we are good to go. Ignoring the rest of the system, what I am going to focus on is the following, given a piece of an image with an MRZ string, how can we parse it best.

Put an image here with an MRZ string from a DNI, annotated with the significance of each part of the string.

Explain that this is essentially what we are trying to extract from the image. Say that this fits within an API, by which you upload an image and then get back a json with all the data.

Explain that the initial cheap approach was to use tesseract, which is an open source OCR engine, that has been there forever. It currently implements an LSTM network and can be quite configurable.

One of the issues with tesseract under this is that it is usually trained on a corpus of books, not ids. So basically the network is not used to the typesetting and neither is used to the names. The names are also quite problematic, since they can vary quite a lot. What I did with that was basically play around with the settings, until I found a way to load what was a network based on latin charset, without constraint on language, which was about the best approach.

Another problem is that tesseract, at least the new versions based on LSTM, you can't pass a dictionary, a list of characters, weights or anything. There are not many things you can tweak. So if you don't like the results, you either have to use the old engine (works worse), or train your own networks. And for stuff like IDs, well, let's say that it would be hard to come by with a realistic dataset. It is very hazardous data, quite an undertaking, and definitely out of scope for the project.

So basically, there were problems mainly on performing OCR on the names string. I could expand here with explaining different modes of failure and what was going on. I need to succintly explain the modes of failure I observed.

Then go with intuiton number one. Maybe I could use a dictionary of names and then try to approximate the string to the name that is closest.

Simplification number one of the problem. I could create a trie out of a list of names and then, if I can traverse the string, the string belongs to a real name.

This simplification does not solve the issue at hand but ok.

Then from this simplification, evolve the trie to a finite state machine, with recursivity. Explain how I modified the trie so that it is possible to jump from word to word in the dictionary.

And then explain that this helps a little bit more. Basically, if the string is correct, you will be able to traverse the whole thing using the state machine. If there is an error, it will stop.

Basically this would be a good error detector already, although we are still not fixing anything.

Now comes the second insight. If we treat the input as a conditional probability, then we can have estimate a likelihood that the next character is X given that the input was Y. Obviously if they match, the probability will be higuer, than if they don't.

And now we have all necessary elements to solve the problem effectively. Essentially what we want is to traverse our state machine up to n steps (n being the length of the string) and extract the branch that maximizes our probability. We are not traversing graphs, and we can just apply graph theory and algorithms for path finding.

And then basically explain that I implemented a bastardized greedy search that is not optimal, but works mostly fine in practice (as in, we want to explore a few paths, but it usually doesn't make a lot of sense to deviate too much from immediate best matches). Usually taking a suboptimal step will already pay off at the 2nd or 3rd degree, so you don't need to look that deep to have results that are cool.

Put here some results and stuff of what the algorithm does to solve the issue at hand.

Explain as well that this had the advantage of being easy to expand. Adding more names to the dictionary essentially improves what it can come up with. That is also one of the drawbacks. It is impossible for the system to come up with a word it doesn't have on the dictionary, so you really need to work on that data. Still, it is much easier to come by names than it is to come by id cards.

Another plus of this approach is that any improvement on the LSTM engine automatically improves the system. And if we essentially worked the system to suit it to our own purposes, then merging the improvements together becomes much harder. So there you go, an added benefit.

It would be cool to explain how this ties up with the research, but it might be even a better idea to do like a white paper on word predictor systems on another article. Maybe similarly to what I did with the 