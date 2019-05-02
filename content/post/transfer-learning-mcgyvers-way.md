---
title: "Transfer learning, the MacGyver's way: Ensembling an OCR LSTM model with a probabilistic word predictor"
date: 2019-04-15T00:44:02+02:00
draft: true
---
How can you improve the accuracy of a model trained on a different dataset than the problem at hand? In this post I'll show how I created a probabilistic word predictor using a dictionary and the input from tesseract, an open source OCR algorithm.

The result of ensembling the two models yields a much better performance, is cheap to run and easy to improve on.

<!--more-->	

<!-- context: Why? -->
This project was an assignment for a client, that wanted to automate part of their id check workflow. There are solutions in this space, but they do cost quite a bit if you have to scale them and part of the problem they wanted to solve is not covered by those solutions, so basically this project started as an exloration of how feasible would it be to develop such a solution (id card reader).

<!-- What -->
ID cards can be very different, but most modern designs and passports have what is called a machine readable zone (MRZ). This format is shared among id cards and includes most of the information you would want to extract in a neatly packaged format.

<!-- Put annotated image of a MRZ  -->

As part of my first attemps into parsing information out of an id card, was to read the MRZ properly. Basically, I will not focus on segmentation nor on image preprocessing, nor other parts of the OCR pipeline (I might write about it at a later date), but just on the problems I found when doing the MRZ.


<!-- Initial setup -->
The initial approach to OCR, after segmentation and all is done, was to employ tesseract. Tesseract is basically the goto open source solution for OCR. It has a long history, has been worked upon for years and has bindings to most languages. Heck, there are even MRZ parsing libraries in python, so everything looked pretty good right?

Explain a bit of what I do. Say I segment the id card (how doesn't matter at the moment), and basically apply OTSU for thresholding, so I pass tesseract stuff like [example image].

<!-- Playing with tesseract -->
Explain the dials available to config tesseract. I could take an example MRZ and then put examples of how the OCR is working in different conditions. Basically, the conclusion here is that I've got some decent parameters, but I've got problems performing name segmentation as it stands.

Then comes the results. Basically it's not that bad, but it leaves quite a bit to be desired still. I can explain here things I played around with, such as using Latin, or different parsing modes. I can also mention what is going on with LSTM and the old engines. All pretty good stuff. Essentially a review of the process I followed to tweak around the already existing product without having to change too much.

<!-- What can we do about it? -->
Then present the results with the current limitations. Like, this is the best I can do without fundamentally changing the approach. What options do I have to improve on this?

My hypothesis why this goes wrong: Probably the font and the type of text is just wildly different from what tesseract has been trained on. Especially the whole `<<<<<<` thing. Would it be possible to do transfer learning and train the dataset with specific data related to id cards? Sure, it would be possible. This has a few problems though:

- Not clear how it's done (technically)
- How do you come about this kind of data? Difficult to create a proper training set
- You'd probably have to synthetically generate the dataset. So lots of resources spent creating fake MRZ codes (which would be cool, but also take time)
- Ultimately, you're creating a fork of the program, so it may be harder to benefit from improvements in subsequent releases of tesseract if you go down that path
- The path seems resource intensive, for a task which was mostly a prototype, so it's not feasible from a business perspective to pursue
- I do not have expertise with fake dataset generation. So it could be done, but it wouldn't be automatic, and surely I might end up creating problems such as the synthetic images are not quite as representative of the real world scenarios as they should be, so shame on me for that.

Since this paths was fraught with problems and uncertainty, I wanted to explore other options.

<!-- Analyzing the issue in detail -->
Then it's when I analyze the problems more in detail. You can basically observe a series of patterns in the sort of errors that tesseract does which are pretty consistent. It's not as if it is totally botched. It's more that it gets confused and outputs nonsensical words. So I thought, hey, we have a lot of prior information regarding how the output should look like. Why don't we make use of this prior knowledge to help tesseract get it right?

If I had to write down exactly what happens: Most of the times the letters get identified correctly. But then the character `<` gets swapped by a wide range of characters. Sometimes multiple characters. So I need something that kinda does spell checking, although the main problem tends to be at breaking apart the words and not so much in the letters in-between.

<!-- Framing the problem -->
So the idea transformed itself into, let's see if I can find a set of heuristics that would help me fix the output from tesseract. And also, if I have a good enough dictionary of names and last names, won't I be able to know if a word makes sense or not? That was the initial snugget.

Now, how should I continue the article? I guess that a way could be expanding on the type of failures I observed. Basically I could lay down the format, as it is expected in the MRZ string. And after I've done so, explain what I was observing. Basically, invented characters, inconsistent number of characters, wrong spacing, etc. Try to come up with a list of all
the biases that the program created. Then, once I have that list, I can name a few approaches, such as trying to find the longest, non-overlaping number of substrings in the text (but then say, hey, this would fail in such and such cases), or something more naive, as trying to split on spaces, etc. I could link to the article falsehoods that programmers believe about names, when I mention how much names can vary and how little you can assume.

Basically, from this what I conclude is that I can't take any of what tesseract tells me as a hard truth. And the structure of the names is not even that easy to predict. Because there are many formats possible:

- last_name name_1
- last_name name_1 name_2
- last_name_1 last_name_2 name_1
- last_name_1 last_name_2 name_1 name_2
- ...

So it's essentially a huge clusterfuck and very difficult to make any hard assumptions as to how the data will be presented. Pretty much the only assumption I can make is the following:

- space [last_name | name] > recursivity

But do the above as a graph.

So on the one hand, I have tries, as an auto suggestions model for text prediction.
Probably at this point in the article it is actually worth to introduce the trie data structure and explain how it is used (generally) in text prediction.

I can explain it, and then also put some cases on how it is used. Now that means that I should perform proper research in the literature, as I've basically reinvented the wheel and I'm not really that aware of what has been done already in the state of the art.

Once I've put this a little bit into context, I start talking about how I transform the current problem into a structure apt to perform text prediction and correction. There are 2 key ideas:

- I can convert the trie into a recursive structure that essentially works both as a regexp and a graph. A regexp with the following format (put graph below)
- Draw a trie as a graph, and then draw a virtual source and sink. So what you want is finding a path that will minimize the weight to connect source from sink. I can also mention a few properties from this path, given that the underlying data structure is a trie (I think it's an acyclic path) and maybe something else.
- Now we are already very close to a solution. If it's a graph problem, basically we have good algorithms to find a solution. From simple BFS / DFS, to Dijkstra or A\*. Now we do need a way to put weights to those edges.
- This is where the conditional probability comes into play. Basically, I rethink the output of what tesseract gives me as a bayesan conditional probability. So for each letter what I do is transform it into a probability of p(charTrie | charTesseract). I create a function that will compute this conditional probabilities for each branch, and this is the weight of the edges of the graph.

Those two insights essentially solve the problem. Now it's a matter of implementation. There is still a few problems though. As the problem is described, the trie could have exponential growth, so I should look into what algorithm might be best to avoid hitting a brute force solution.

Now I would enter the details section. This is where I go into the technical tricks that go into making what is essentially an exponential growth problem into a linear one. Both in computing time and memory. It is at this stage that I should explain the trick of how I created the trie (the trie itself is a recursive structure). And then I should also explain how I've bastardized the clean approach of the original graph to something
that tries to find the branch that maximizes probability given a specific depth. Say that I also make use of a few tricks, such as adding spacing, to make sure that predictions will be forced to return a completed name, and they won't prioritize giving me a broken name.

After the technical details, I should maybe go into what I've done in terms of finding the dataset, how I generate the trie, how I store it (the pickling and stuff). Basically I can demonstrate that is a very efficient data structure. I can even do a few benchmarks of how everything works and how fast it does, how it scales. Then something like how I choose the parameters on the greedy BFS and so on and so forth.

Once I've done all the demos on how things are fixed, and what is broken, go into problems. Basically, the huge problem is that the system is not capable of outputting names that are not on the database. This is huge, but it is also true that it's very easy to improve on. Basically if we can periodically update our database, the system will get better. It is also MUCH easier to grow a database of names than it is to do something similar with images, with variations and the like. The problem is much simpler and way cheaper to improve on. Also, since it is decoupled from tesseract, any improvements on the engine will make less demands of our engine, so the likelihood of shit going wrong decreases, while the interactions between the systems remain simple, so that's all good.

I can also say that we can apply the same concept throughout other fields in the OCR. For example, country codes and similar. It would be even easier to generate lists of valid codes and numbers, and making new text predictors. The only part that requires tweaking around is the conditional probability function, that needs to be adjusted based on the kind of errors you observe empirically with your test data, but that is really not that complicated to do.

And finally, I guess that from a theoretical point of view there are a few things that are missing. Like, there is no sense of probability of words. Or there is no weight to point longer words higher, or anything like that. Basically, the concept of memory in my implementation is very limited. The search algorithm eventually discards all other possibilities, so if a mistake is made early on, we lose the possibility of backtracking and following a more promising branch. This is a bit of a shame, probably requires tweaking the model to make it smarter (it means I should read more into the field to understand it deeper), but in practice, the results are already pretty good for what was just a prototype.

And I haven't even talked about the text splitter for the names, but I can probably skip that, even though it's also cool.

But I think in terms of editorial line, what I should strive for is trying to explain the thought process behind designing a system like that. As in, I want to explain that things were not necessarily supposed to be that way. That the path towards the solution comes with many twists and turns and wasn't really clear at the start in the least. Also, even the current solution has clear flaws that will need to be taken into account and that under another set of conditions might be reason enough to invalidate the whole things.

I was just thinking now that the literature research on the article might be better in a separate article. Something like a scholar's take on my bayesan trie. This is where I review the state of the art regarding text prediction and correction and maybe analyze what would and wouldn't have worked. But again, this is a huge amount of hours both in research and in writing and in testing this out, so there's that. It could be good to do more of that for an inevitable Q&A in a presentation though.

If I had a dictionary with names, isn't there a way to perform spell checking on the MRZ string to fix its problems? -> This is my hunch. There must be a way. Think of spell checkers, smartphone keyboards, etc.

So one of the first ideas is, If I had a generator of valid strings for names, and then I compared the distance with the string I got, I could choose whatever was closest and call it a day, right?

So how can I get this magic string generator? Tries enter the game then. I could explain tries. Used for retrieval, they are also used for suggestion. For example, I could generate a trie out of a few names, and you would only be able to traverse it if the name was valid.

Then I use tries and generate a FSM with recursivity, to generate like an infinite name machine. Now I can generate strings as long as I want

So I have a dictionary. Then I use a trie data structure to represent it. Then I use recursivity to generate a FSM capable of creating sequences of names. So basically, at this point I have a sequence that can only be traversed if you input correct names, followed by a space or spaces. And it is at this point that the bayesan probability enters in. So I branch out the transitions, but I attach a probability to them.

And finally finally finally, I convert the problem into a graph problem, and use the probabilities to find its shortest path.

And I need graphs to explain those 3 leaps step by step, at least in a simplified manner. Maybe with just like a name or something

So after I've done the handwavy thing, I go into the details

- Find a name database and preprocess it
- Create a trie out of this database
- Generate the recursive FSM
- Greedy BFS with bayesan probability

I should also annotate a few tricks, such as putting spaces at the front and end of the string.

Then I can benchmark this shit, maybe go into the O(N) complexity of it all.

Finally show some examples of what it does (the before and after). And also display some problems. Especially that it will get confused if there is another name in the dictionary that matches but doesn't necessarily make sense in the context, but I can live with that. Other than that, adding names into the dictionary is a pretty easy solution, compared to retraining the LSTM model.


**FORMAT:** Could be a 5-10min flash talk, but would work better as a 20-30 minute talk. No live coding. Maybe a short live demo at the end.

**OVERVIEW:** 

**OUTLINE:**

- Present the problem (general, reading MRZ)
- Present the issue (accuracy of tesseract being low)
- Explore available options (tune parameters, different engines, etc.)
- Explore more options (transfer learning? is it feasible?)
- Exploit the structure of the problem and the errors
- Stealing a dictionary of names
- Tries and word predictors
- Combining tries with a probabilistic model
- Creating a regex out of a trie
- Greedy BFS
- Results
- Explain limitations and possible improvements
- Q&A