---
title: "Deep Learning in Production Part 2: Dockerize for deployment"
author: "Octavi Font"
date: 2021-04-16T14:05:17+01:00
cover: "/media/post/deep-learning-in-production-part2/docker-logo.jpg"
draft: true
---

Your newly trained models are ready to go and now it is time to put them in production. How do you go about it
You have your new trained models ready, and now it is time to deploy them to production. How

<!--more-->

TBD

Maybe I should divide into a multiple series of posts? Like, it makes sense to explain how to go from a simple notebook that you run randomly as an example from the pytorch or keras website, so something of a more repeatable environment.

I know that there are environments such as collab notebooks and the like, where everything is in the cloud and basically the data scientists don't have to worry about anything at all infra wise. But if you still want to have control exactly about what you are doing, these techniques might be worth it.

I think that it would make sense to give a bit of context on who might benefit best from setups such as this. I think they are very good to start out with. Especially if you are a smaller company, or research lab with bare metal hardware you want to use for your experiments.

Probably if you are a cloud native company, with engineering resources and dedicated data scientists and ifra team, you'll benefit from staying cloud native, and enjoy the benefits of multi instance GPU training and all of that. But for now, let's stay for what you can do in more simple cases.

This approach is still useful if you are playing with different technologies, projects and frameworks, since it needs to install the least amount of components on your bare metal hardware. I've used it successfully on workstations I've owned and also HPCs where I didn't have access to the setup or anything. It translates well into docker and it can even work well in a GPU-through docker situation.

It will also let you scale to multigpu training in the same workstation without trouble as well. And if you work with smaller datasets, or your data is not in the cloud, you have a small operations budget, etc. It's a really good option to perform development work and still have a good path to deployment later on.

## Introduction
Introduce the problem we are trying to solve. Essentially, early prototyping and training of models in jupyter notebooks can be hard to translate to production if you don't take good care of your virtual environments and dependency management. Additionally, if you are training deep learning models, you will have the extra annoyance of having to deal with nvidia drivers and the cuda toolkit, which is pretty finnicky and outside of the pip realm. To make things worse, you may be working with multiple models, built on different versions of PyTorch or Tensorflow, which may require different and incompatible versions of the cuda toolkit, etc.

This is a 2 series post on how to make this process a bit more bearable and how to package it for production.

Maybe I could do like a 2 part series.

- conda vs pip. Why it is interesting when dealing with deep learning (especially it frees you of libcuda problems)
- dockerize the conda environment. How to create base images that contain everything and reuse them for multiple services in your docker-compose.yml
- Add the weights to the docker image itself. This way you can ship this to production as a single package. You don't even need to download them on startup. It's a single binary, containing weights and code. Not the most efficient in terms of space, that is true, with the extra dependencies added, but still serviceable.
- Additionally, I think it is worth mentioning that this technique has the benefit of being able to use the GPUs through docker, if you configure it properly. Since the image has all the libraries installed, if you route the GPU, you can actually use it, even in the cloud. That is pretty cool, if you want to accelerate the inference step of your code.

Honestly, the first part is mostly about dependency management and why conda is a bit better, at least for things like deep learning. Like, sure, you could use docker also for development, but GPU passthrough setup is a bit more of a pain, and you need to be smarter to setup properly the scripts. And sometimes you just don't want to have to deal with volumes and the like, so if you can avoid it without much cost, all the better.

The second part is how we encapsulate this conda environment and actually ship it to production. Since we have already done most of the work, pretty much the only thing left is for us to package the thing and add the weights. With the additional benefit that libraries do work with CPU by default and, if we configure it properly, it is also possible to execute the same image with GPU support for an added bonus.

A thing that is nice about conda, is that you can even execute it in environments where you don't have a lot of permissions. In the case of docker, you need a user with docker privileges, which you might not have. For conda, you should be able to setup everything locally, even with a user without any permissions. This can be useful if you are using the HPC of your university lab. You can setup everything locally, including cuda toolkit driver versions, and just run the code with everything local. As long as the GPU driver is compatible, you are good to go, and the possibilities this is the case are much larger than otherwise. Pretty good alternative if you need to run your experiments there.

