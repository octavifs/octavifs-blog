---
title: "Transfer learning, the MacGyver's way: Ensembling an OCR LSTM model with a probabilistic word predictor"
date: 2019-05-23T14:18:01+02:00
draft: true
---

How can you improve the performance of an OCR LSTM model when applied to a setting it wasn't trained on? Is it absolutely necessary to kick-off a data collection effort and use transfer learning to retrain the network? This is how I improved accuracy on the cheap by ensembling the original model with a custom-made probabilistic word predictor.

<!--more-->

![Passports nowadays have both biometrics and features enabling its readability via OCR software](/media/post/transfer-learning-mac-gyver-ensembling-ocr-lstm-probabilistic-word-predictor/passport-article-heading.jpg)

### The big picture
This story starts as part of a processes optimization project I'm conducting with a client. They wanted to develop some in-house technology to scan IDs automatically to speed up their enrollment process. This required the creation of an entire OCR pipeline: automatic segmentation and detection of id cards, detection of the fields, preprocessing the images and finally applying OCR on the segments to extract the data.

In this article we'll just focus on one piece of this puzzle: How to improve the accuracy of the OCR when applied to the Machine Readable Zone (MRZ) of an ID card. After performing some experiments with my early prototype, I discovered that the off-the-shelf OCR solution I was using wasn't particularly precise with the typography and character set used in the MRZ of the ID. Here's an example of what I'm talking about:

MRZ string from my ID card
:   ![MRZ string containing the name](/media/post/transfer-learning-mac-gyver-ensembling-ocr-lstm-probabilistic-word-predictor/mrz-name-example.jpg)

OCR transcription
:   <blockquote>FONT&lt;S&lt;SOLA&lt;&lt;SOCTAVI&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;</blockquote>

This case, while not particularly bad, is a pretty good example of the issues I had with the default OCR model. The first one being that the character `<` tends to be confused with `S` or `K` and the second one being that `<` is transcribed as multiple characters (`<S<` in the separator between `FONT` and `SOLA`).


### Why focus on the MRZ? What is it?
There is a wide variety of valid state-issued ID cards that citizens can use for identification purposes. From passports, to national ID cards, social security numbers, driving licences, etc. You also need to take into account the edge cases introduced by alien citizens, which have their own kind of IDs and Visas, and wildly different formats depending on the immigration policies of the state they reside in. And if that wasn't enough, be sure that the same type of ID card will have different formats in circulation, and you need to support all of them.

First task then, was to find the least common denominator that I could use to extract data from the largest possible set of ID cards with the least amount of work. Thankfully, this is not 


Different countries have different formats, different versions of the same format, 
[Wikipedia on MRZ](https://en.wikipedia.org/wiki/Machine-readable_passport)
Fortunately, most new state issued id cards and passports have a machine readable zone, containing most of the id information in a format prepared for OCR. MRZ is a standard (ISO xxxx) introduced in the 1980s that has seen wide deployment throghout. Try to put some more info about the current usage and deployment of this technology. Nowadays, most id cards also have an RFID chip for biometrics, which is what people use in the ePassport gates.

![Passport with MRZ string. Source: https://www.canada.ca/en/immigration-refugees-citizenship/corporate/publications-manuals/operational-bulletins-manuals/identity-management/naming-procedures/read-travel-documents.html](/media/post/transfer-learning-mac-gyver-ensembling-ocr-lstm-probabilistic-word-predictor/mrz-passport-sample.jpg)


Now that I've explained that the MRZ is a standard, and that mostly DNI, NIE and passports have it, and also that it contains most of the information that the client needed for identification purposes, say that OK, we are good to go. Ignoring the rest of the system, what I am going to focus on is the following, given a piece of an image with an MRZ string, how can we parse it best.

![https://www.researchgate.net/publication/269629982_A_Proposal_for_a_Unified_Identity_Card_for_Use_in_an_Academic_Federation_Environment](/media/post/transfer-learning-mac-gyver-ensembling-ocr-lstm-probabilistic-word-predictor/mrz-breakdown.png)

Explain that this is essentially what we are trying to extract from the image. Say that this fits within an API, by which you upload an image and then get back a json with all the data.


## Initial approach and limitations
Explain that the initial cheap approach was to use tesseract, which is an open source OCR engine, that has been there forever. It currently implements an LSTM network and can be quite configurable.

One of the issues with tesseract under this is that it is usually trained on a corpus of books, not ids. So basically the network is not used to the typesetting and neither is used to the names. The names are also quite problematic, since they can vary quite a lot. What I did with that was basically play around with the settings, until I found a way to load what was a network based on latin charset, without constraint on language, which was about the best approach.

Another problem is that tesseract, at least the new versions based on LSTM, you can't pass a dictionary, a list of characters, weights or anything. There are not many things you can tweak. So if you don't like the results, you either have to use the old engine (works worse), or train your own networks. And for stuff like IDs, well, let's say that it would be hard to come by with a realistic dataset. It is very hazardous data, quite an undertaking, and definitely out of scope for the project.

So basically, there were problems mainly on performing OCR on the names string. I could expand here with explaining different modes of failure and what was going on. I need to succintly explain the modes of failure I observed.


**ZARO<GARCIA<<AIDA<<<<<<<<<<<<**

> ZAROSGARCIA<<AIDA<<<<<<<<<<

**TORRA<SERRA<<EMMA<<<<<<<<<<<<<**

> TORRACSERRACSEMMACKCCK<KE

**FONT<SOLA<<OCTAVI<<<<<<<<<<<<<**

> FONTCSOLA<SSLOCTAVIKCKKLKK<<<<<Ė<<

> FONTCSOLACKLOCTAVICKCCKKLKLKLKKĖ<Ė<


## Initial intuition
Somehow I should introduce the idea that yes, the data is garbled in a way, but not so much that you couldn't infer what the original name was most of the time. I was thinking that a dictionary could be used probably and then calculate some metric of distance to the words. Or maybe I could use something like a text predictor, similar technology than what we have in our smartphones, but applied to the OCR output.

Then go with intuiton number one. Maybe I could use a dictionary of names and then try to approximate the string to the name that is closest.

## Insight 1: check if the returned string is valid
Simplification number one of the problem. I could create a trie out of a list of names and then, if I can traverse the string, the string belongs to a real name.

This simplification does not solve the issue at hand but ok.

Then from this simplification, evolve the trie to a finite state machine, with recursivity. Explain how I modified the trie so that it is possible to jump from word to word in the dictionary.

And then explain that this helps a little bit more. Basically, if the string is correct, you will be able to traverse the whole thing using the state machine. If there is an error, it will stop.

## Insight 2: Conditional probability
Basically this would be a good error detector already, although we are still not fixing anything.

Now comes the second insight. If we treat the input as a conditional probability, then we can have estimate a likelihood that the next character is X given that the input was Y. Obviously if they match, the probability will be higuer, than if they don't.

And now we have all necessary elements to solve the problem effectively. Essentially what we want is to traverse our state machine up to n steps (n being the length of the string) and extract the branch that maximizes our probability. We are not traversing graphs, and we can just apply graph theory and algorithms for path finding.


## Problem setup
And then basically explain that I implemented a bastardized greedy search that is not optimal, but works mostly fine in practice (as in, we want to explore a few paths, but it usually doesn't make a lot of sense to deviate too much from immediate best matches). Usually taking a suboptimal step will already pay off at the 2nd or 3rd degree, so you don't need to look that deep to have results that are cool.

## Results
Put here some results and stuff of what the algorithm does to solve the issue at hand.

## Drawbacks and strong points
Explain as well that this had the advantage of being easy to expand. Adding more names to the dictionary essentially improves what it can come up with. That is also one of the drawbacks. It is impossible for the system to come up with a word it doesn't have on the dictionary, so you really need to work on that data. Still, it is much easier to come by names than it is to come by id cards.

Another plus of this approach is that any improvement on the LSTM engine automatically improves the system. And if we essentially worked the system to suit it to our own purposes, then merging the improvements together becomes much harder. So there you go, an added benefit.

## Closing
It would be cool to explain how this ties up with the research, but it might be even a better idea to do like a white paper on word predictor systems on another article.

Explain that I've seen tries used for autocomplete, but never combined with the conditional probability aspects that I am applying in this case.

Maybe on of the last paragraphs should be about how important it is to frame problems correctly. My main motto should be something like, method trumps everything. It is super important to be methodical, break down problems, try to develop intuitions, play with ideas. In this case, it can be clearly seen how something that was broken and was quite complicated to solve by brute force, by simplifying the problem into easier ones, then I found a way to combine multiple approaches into known problems in CS that make sense. It is a simple mode, it is not hard to implement, there are good fast algorithms to solve them and is easy to enhance in the future. So overall it's pretty good stuff.

My value proposition then is probably not so much tied to execution of very concrete pieces, but to the overall structure of whatever you want to do. I can come in a break down what is it you want to do in actionable steps, that then can be implemented. But this work of separating the parts, seeing how everything comes together, what makes sense, what doesn't, what needs to be put more effort in, what should be prioritized. This is something I actually really like to do. I like to do it and at the same time I hate to do it, because it is really hard. Like writing an article like this.

I have the structure now, but I have to put in the real work to write it well, and efficiently, and it is a fucking pain in the ass to be honest. It really pains me so much that I require so much time to break down the problem and put it succintly in the different parts it is composed of. It is true though that time makes it much better. It really feels like as time passes, things are more clear and less verbose. That I need less words to put the ideas forward, but still. So MUCH fucking time. I don't know if I am working as efficciently as I should, really. Or whether I'm slacking off too much or what is going on.