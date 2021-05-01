---
title: "Deep Learning in Production Part 1: Reproducible Environments"
author: "Octavi Font"
date: 2021-04-16T14:05:17+01:00
cover: "/media/post/deep-learning-in-production-part1/conda-logo.png"
draft: true
---

Reproducible python environments can be tricky, especially so when your codebase requires external non-python dependencies that need to be installed outside your virtualenv. Docker is the defacto tool to solve this problem nowadays but, if your workflow requires access to specific hardware resources such as GPUs, things get a bit more complicated.

In this post I cover my approach to repeatable environments with GPU support and a minimum amount of external setup.

<!--more-->

![XKCD python environment madness](/media/post/deep-learning-in-production-part1/python_environment_xkcd.png "source: [https://xkcd.com/1987](https://xkcd.com/1987)")

## Python package management

Python's package management story is a convoluted affair compared to Rust's [Cargo](https://doc.rust-lang.org/cargo/) or Javascript's [npm](https://www.npmjs.com/). The language was publicly released 30 years ago and the development landscape has changed much since then. There's never been more people using it, on all kinds of projects, at all sorts of scales. This doesn't come without drawbacks, however, and currently one of the roughest edges when developing in python revolves around package management and distribution.

If you've worked on multiple python projects before, you will be pretty familiar with these setup requirements to get a working dev environment:

- python interpreter with a compatible version (2 vs 3, but also pretty frequently a specific flavor of 3.x)
- system wide libraries installed via apt (required to build a dependency or necessary for a dependency to run)
- virtualenv installed with pip, containing the project's python dependencies

If you are lucky enough that all your project dependencies come packaged as a wheel binary, you might not even need to install any system wide library to your dev machine. Everything can be done from `pip`. Also, if you want a better experience managing virtual environments and dependencies, there are alternative package manager projects such as [`pipenv`](https://pipenv.pypa.io/en/latest/) and [`poetry`](https://python-poetry.org/) that improve on the workflow and dependency resolution consistency over pip [^pip_dependency_resolution].

[^pip_dependency_resolution]: Historically `pip` dependency resolver has been pretty limited and is known to let the user install mutually incompatible versions of a dependency. pip v20.3 onwards offers [improvements](https://pyfound.blogspot.com/2020/11/pip-20-3-new-resolver.html) on the resolver, although projects such as pipenv or poetry have much stricter consistency goals. The whole topic is worth another series of posts in itself.

If you can't avoid installing non-python dependencies, the typical solution is to package your whole environment in a `Dockerfile` and work with that. This way, neither the system wide dependencies nor the virtualenvs are a problem, since both of them are contained within a Docker image. But, **if you need access to your GPU, by default, Docker will not let you**[^docker_gpu_support].

[^docker_gpu_support]: It's possible to setup Docker and docker-compose with GPU support with [nvidia-container-runtime](https://github.com/NVIDIA/nvidia-container-runtime). I'll detail its usage in the following posts.

## Conda to the rescue

[`conda`](https://docs.conda.io/en/latest/) is a package manager typically used for Python, but not limited to it. This means you can use it, like `pip`, to manage all your python dependencies but, additionally, it will also manage those pesky system-wide dependencies you sometimes needed to preinstall which, in the world of deep learning, essentially means that we don't need to worry about which CUDA version we have installed into our system, since `conda` will manage this for us. Another positive aspect of this approach is that those non-python dependencies also get installed in an isolated environment. So it is perfectly possible to have multiple projects, locally, using conflicting packages and library versions. Even CUDA. Without the need to Dockerize anything.

My recommended approach, if you're not tied to any other of the alternative package managers, is to setup my projects with `conda`, use the `conda` environment to develop locally and dockerize the project for deployment in production. The amount of setup is minimal, the environment is self-contained, and it's the easiest way to get your GPU running and test your experiments with. It's also really easy to package into a docker image and or to setup the same environment into environments where you might have limited restrictions. For example, I've executed training scripts on my University HPC with this `conda` setup without the need to limit myself to the installed versions of the software available on those machines.


## Draft

Mention the problems you typically find more in detail, and why dependencies should be pinned.

- Libraries are still young and under heavy development. API may not be super stable and some times breaking changes are introduced between minor releases. If dependencies are not pinned, you may inadvertedly end up with broken environments across your team, or worse, in your production image!
- Unfortunately, there are many dependencies on C libraries and external shit being installed. Also, CUDA toolkit and NVIDIA drivers can be a pain in the bum. And frameworks as Tensorflow or PyTorch tend to be pretty particular as to which versions you need installed. This can also be a problem if you have to switch between projects with different technologies pretty frequently, if you have to uninstall your CUDA libraries, maybe even drivers, to adapt them to a specific version. Or maybe you need to force an upgrade on some libraries, with the extra rework required, just so that you can run it alongside your new stack now, etc.

PIP has gotten better, now it has wheels, with binaries built in, so you don't need to have a full dev environment to be able to build the libraries you need to install, which is nice. And there are other possibilities such as pipenv, poetry or conda. And I wonder if you do weird things. Ah, you don't at this zoom level. I wonder if this is actually the normal zoom level? And the other one is some zoomed-in bullshit that I am using? Now that I have reset the zoom level, will it work without me going mad? Because all of these break lines moving back and forth were really making me go a bit looney.

Maybe I should divide into a multiple series of posts? Like, it makes sense to explain how to go from a simple notebook that you run randomly as an example from the pytorch or keras website, so something of a more repeatable environment.

I know that there are environments such as collab notebooks and the like, where everything is in the cloud and basically the data scientists don't have to worry about anything at all infra wise. But if you still want to have control exactly about what you are doing, these techniques might be worth it.

I think that it would make sense to give a bit of context on who might benefit best from setups such as this. I think they are very good to start out with. Especially if you are a smaller company, or research lab with bare metal hardware you want to use for your experiments.

Probably if you are a cloud native company, with engineering resources and dedicated data scientists and ifra team, you'll benefit from staying cloud native, and enjoy the benefits of multi instance GPU training and all of that. But for now, let's stay for what you can do in more simple cases.

This approach is still useful if you are playing with different technologies, projects and frameworks, since it needs to install the least amount of components on your bare metal hardware. I've used it successfully on workstations I've owned and also HPCs where I didn't have access to the setup or anything. It translates well into docker and it can even work well in a GPU-through docker situation.

It will also let you scale to multigpu training in the same workstation without trouble as well. And if you work with smaller datasets, or your data is not in the cloud, you have a small operations budget, etc. It's a really good option to perform development work and still have a good path to deployment later on.


All of this still doesn't sidestep the fact that, if your project 

Talk about pip. pip allows you to install packages, resolves dependencies, and builds binaries, if you need to build something from source. Nowadays there are wheels as well, which is prepackaged binaries, which is very nice. Mostly because before wheels, you needed to have all the dev libraries installed to be able to build a python package, if it had any sort of C extensions or similar. And this, apart from the time it requires to do the build itself, it resulted in some hunting down instructions to add all of the dependencies manually, via apt-get or yum, or whatever your linux distro requires. And that is almost a best-case scenario, because if you were using Windows or OSX, you might be fucked.

Then OK, you have your packages installed. But you might need to work with more than one python version. Or maybe you need different library versions in 2 different projects. Then what? This is why they created virtualenvs for. Now, this is almost a thing of the past, because instead of a virtualenv, what we do is create a docker image, build everything there and bam, isolated pip. And while this is amazing, if your environment requires the usage of special resources, such as GPUs, for the training of deep learning models, or whatever, you might actually need to go back to this virtualenv thingies.

Now, virtualenv is OK, but not the latest thing. You can use pipenv, or poetry, which are newer generation package managers, that integrate virtualenvs, and also have lockfiles, and more strict dependency trackers. Even pip itself is actually improving in terms of package resolution, and avoiding conflicst on the python dependency graph. But it is just not great.

Another problem with all of this crap is that OK, even if you do all of this,


If you've used python to write more than a simple few scripts you are probably already familiar with `pip` and `virtualenv`. When you need to work on multiple projects, the ability to create isolated python environments in your development machine is a must. This allows you to work with different python versions simultaneously, conflicting package versions
You might have to work with different python versions simultaneously, conflicting package versions or j

, especially if you had the need to deal with multiple projects and codebases, 


The language is used by more people than ever before, for more purposes than ever, on much larger scales.

Most of you will be familiar with the `pip` package manager and the usage of `virtualenv` to create isolated python environments.

Python package management story is a much more convoluted affair than Rust's Cargo or Javascript's npm. The language was publically released more than 30 years ago and 
Python's first public release was 30 years ago already, and much has changed since the early 90's. The language has grown a lot, in features and usages, from its early 1.x days.

Python's first public release was 30 years ago, and much has changed since that. Both in the language and
Python is a pretty senior programming language, first published to the public 30 years ago already. And the times have changed. The language has greatly evolved, going from a convenient language to write some quick scripts in, to something used by millions to develop large codebases in, with very complex toolchains and business built around it.

Essentially, the language has grown a lot, python is something else for every developer, and package management can be pretty messy.

I'm pretty sure you are already familiar with the concept of virtualenvs and pip. One to create separate python environments, with specific python versions, if needed. And the other to install python packages.

There are other strategies, such as the classic `setup.py` and `disttools` to build packages. Then also `easy_install`, which I think is deprecated already?
Explain here a bit around pip, virtualenvs, docker, conda, etc.

A history of python packaging until 2009 (itself, history): [source](https://blog.startifact.com/posts/older/a-history-of-python-packaging.html)

## Specific problems in deep learning
What about deep learning development is extra complicated? Why does the normal approach not work?



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

