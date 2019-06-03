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


### Machine-Readable Zone (MRZ) to the rescue
There is a wide variety of valid state-issued ID cards that citizens can use for identification purposes: passports, national ID cards, social security numbers, driving licences, etc. You also need to take into account the edge cases introduced by alien citizens, which have their own kind of IDs and Visas, with their own set of formats and idiosyncrasies that vary from country to country. And if that wasn't enough, be sure that the same type of ID card will have different formats in circulation, and you need to support all of them.

Since the problem space is too big to be tackled at once, my plan was to narrow its scope. That meant finding a strategy applicable to the largest possible subset of ID cards. Thankfully, the necessity to scan IDs fast is not new. In fact, many passports and travel documents include a region for optical character recognition as far back as the 1980s. This region is known as *Machine-Readable Zone (MRZ)* and has been standardized by the [ICAO Document 9303](https://www.icao.int/publications/pages/publication.aspx?docnum=9303) / [ISO-IEC 7501-1](https://www.iso.org/standard/45562.html).

{{< figure src="/media/post/transfer-learning-mac-gyver-ensembling-ocr-lstm-probabilistic-word-predictor/mrz-passport-sample.jpg" title="Passport with MRZ string" >}}


### TD1 documents in detail
The [ICAO Document 9303](https://www.icao.int/publications/pages/publication.aspx?docnum=9303) defines different *Machine-Readable travel documents* based on their format. Passports are defined as **TD3 sized** and credit-card tyled documents are **TD1 sized**. I will center the discussion around the latter, since the happy path for my client is based around the [spanish national identity card](https://en.wikipedia.org/wiki/Documento_Nacional_de_Identidad_(Spain)).

{{< figure src="/media/post/transfer-learning-mac-gyver-ensembling-ocr-lstm-probabilistic-word-predictor/dni-fake.jpg" title="Spanish national identity card. A TD1 sized travel document">}}

The standard affects the size, structure and contents of the document. It segments it in 7 zones, front and back. Each of those zones are used for a particular piece of information, that needs to appear in a certain order. This is very helpful from an image preprocessing perspective, since it ensures that the segmentation efforts performed on one type of card will easily transfer to another as long as it adheres to the standard.

{{< figure src="/media/post/transfer-learning-mac-gyver-ensembling-ocr-lstm-probabilistic-word-predictor/td1-zones.jpg" title="TD1 card zones" attr="source" attrlink="https://www.icao.int/publications/Documents/9303_p5_cons_en.pdf">}}

The MRZ in TD1 sized documents consists on 3 lines of ASCII text, 30 characters in length. The only valid characters are numerals `[0-9]`, the 26 capital Latin letters `[A-Z]` and the filler character `<`. For more specific rules regarding apostrophes, diacritical marks, transliteration, etc. there is a good breakdown available on [the wikipedia article](https://en.wikipedia.org/wiki/Machine-readable_passport#Names). Below I've added a detailed diagram on the fields and format for the MRZ string:

{{< figure src="/media/post/transfer-learning-mac-gyver-ensembling-ocr-lstm-probabilistic-word-predictor/mrz-breakdown.png" title="TD1 MRZ string breakdown" attr="source" attrlink="https://www.researchgate.net/publication/269629982_A_Proposal_for_a_Unified_Identity_Card_for_Use_in_an_Academic_Federation_Environment">}}


### Initial approach and limitations
Now that we have the introduction out of the way, we can delve into the implementation details of the solution. As I mentioned initially, the plan is to develop an OCR solution capable of parsing the MRZ string of a pre-segmented region of interest. On the surface, the problem looks quite straightforward: the character set is restricted and there is good contrast in the area, so as long as the OCR engine is accurate, we just need to parse its output acording to the MRZ format that I detailed on the section above and we'd be done.

{{< figure src="/media/post/transfer-learning-mac-gyver-ensembling-ocr-lstm-probabilistic-word-predictor/mrz-roi.png" title="ROI used as input for our MRZ OCR implementation">}}

After some research on OCR engines, I found the [Tesseract project](https://github.com/tesseract-ocr/tesseract). Tesseract is an open source OCR library, currently maintained by Google. It is a project with a long history, dating as far back as the 90's, initially developed under the umbrella of HP. On its latest version (v4) there is a new engine based on Long short-term memory neural networks, with improved accuracy over its predecessor. It also supports multiple languages, segmentation modes and tuning options. You can easily install it on ubuntu via `apt` and it is simple to integrate in a python project thanks to the [pytesseract](https://pypi.org/project/pytesseract/) bindings.

With such a strong initial impression, it was time to put it through the paces, so I proceeded to test it against a small dataset of real-case MRZs. After some tries, I settled on the following runtime options:

1. Language needs to be set as Latin
2. The rest of interesting options only work on the previous engine
3. It is not even advertised how to install languages for the previous engine
4. Even on the previous engine, the options are kinda broken
5. Even with this, the new engine works better, but you pretty much cannot tune anything

Now I want to put here the parameters I use tesseract with, why I use them, and what else is tere. Basically say that the language package from the old engine is incompatible with the new and that many flags, such as the dictionary, or the one to limit the output of characters to a subset only work with the old engine. Which is a total shame, since the new engine is better overall, but far from perfect. Since names and the character `<` is unlikely to appear in the training corpus, the results for it are rather abysmal, and we just get lots of garbage.

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


## Intuition
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


## Implementation
And then basically explain that I implemented a bastardized greedy search that is not optimal, but works mostly fine in practice (as in, we want to explore a few paths, but it usually doesn't make a lot of sense to deviate too much from immediate best matches). Usually taking a suboptimal step will already pay off at the 2nd or 3rd degree, so you don't need to look that deep to have results that are cool.

## Results
Put here some results and stuff of what the algorithm does to solve the issue at hand.

## Drawbacks and strong points
Explain as well that this had the advantage of being easy to expand. Adding more names to the dictionary essentially improves what it can come up with. That is also one of the drawbacks. It is impossible for the system to come up with a word it doesn't have on the dictionary, so you really need to work on that data. Still, it is much easier to come by names than it is to come by id cards.

Another plus of this approach is that any improvement on the LSTM engine automatically improves the system. And if we essentially worked the system to suit it to our own purposes, then merging the improvements together becomes much harder. So there you go, an added benefit.

## Conclusions
It would be cool to explain how this ties up with the research, but it might be even a better idea to do like a white paper on word predictor systems on another article.

Explain that I've seen tries used for autocomplete, but never combined with the conditional probability aspects that I am applying in this case.

Maybe on of the last paragraphs should be about how important it is to frame problems correctly. My main motto should be something like, method trumps everything. It is super important to be methodical, break down problems, try to develop intuitions, play with ideas. In this case, it can be clearly seen how something that was broken and was quite complicated to solve by brute force, by simplifying the problem into easier ones, then I found a way to combine multiple approaches into known problems in CS that make sense. It is a simple mode, it is not hard to implement, there are good fast algorithms to solve them and is easy to enhance in the future. So overall it's pretty good stuff.

My value proposition then is probably not so much tied to execution of very concrete pieces, but to the overall structure of whatever you want to do. I can come in a break down what is it you want to do in actionable steps, that then can be implemented. But this work of separating the parts, seeing how everything comes together, what makes sense, what doesn't, what needs to be put more effort in, what should be prioritized. This is something I actually really like to do. I like to do it and at the same time I hate to do it, because it is really hard. Like writing an article like this.

I have the structure now, but I have to put in the real work to write it well, and efficiently, and it is a fucking pain in the ass to be honest. It really pains me so much that I require so much time to break down the problem and put it succintly in the different parts it is composed of. It is true though that time makes it much better. It really feels like as time passes, things are more clear and less verbose. That I need less words to put the ideas forward, but still. So MUCH fucking time. I don't know if I am working as efficciently as I should, really. Or whether I'm slacking off too much or what is going on.