---
title: "pybind11 builds in poetry"
cover: "/media/post/pybind11-builds-in-poetry/python-cpp.png"
tags: ["pybind11", "poetry", "build systems", "python"]
date: 2021-10-17T00:34:05+02:00
draft: false
---

Recently, I've been writing some C-extensions to speed up some performance critical code in Python and while trying to setup *pybind11* on a project managed with Poetry I realized there was no clear documentation on how to setup the build process correctly. Here's a short write-up as in how to sort it out.

<!--more-->

[pybind11](http://pybind11.readthedocs.io) is a lightweight header library to easily create bindings between C++ and Python code. Inspired in [Boost.Python](https://www.boost.org/doc/libs/1_58_0/libs/python/doc/) but without Boost's baggage. The project's documentation offer 2 examples on how to setup *pybind11* with [setuptools](https://github.com/pybind/python_example) or [cmake](https://github.com/pybind/cmake_example), but if you want to use poetry's own build system, those resources won't be enough to solve your problem.

Poetry has support for non-pure Python projects [since 2018](https://github.com/python-poetry/poetry/issues/11). It has never been particularly well documented though. The latest info on the project regarding the support status of this feature would be [this issue](https://github.com/python-poetry/poetry/issues/2740). This [GitHub project](https://github.com/sdispater/pendulum) also contains a working example on how setup a C-extension build.

For our particular case, we will start installing pybind11 with poetry on our project's folder:

    $ poetry add pybind11

Next, we will add the following section to `pyproject.toml`:

    [tool.poetry.build]
    script = "build.py"

Now, on the root of our project, let's create `build.py`. It needs to have a `def build(setup_kwargs)` function, which will be invoked upon executing `poetry build`. For our *pybind11* example we can set it up like so:

    from pybind11.setup_helpers import Pybind11Extension, build_ext

    def build(setup_kwargs):
        ext_modules = [
            Pybind11Extension("pybind11_extension", ["pybind11_extension/src/main.cpp"]),
        ]
        setup_kwargs.update({
            "ext_modules": ext_modules,
            "cmd_class": {"build_ext": build_ext},
            "zip_safe": False,
        })

In this example, we are building a C-extension module called `pybind11_extension`, using the C++ source in the `pybind11_extension/src`folder of the project. Change and modify as necessary for your particular use case.

Finally, to build and install the package, run:

    $ poetry build
    $ poetry install

You should see the compilation process being executed in your shell. The `poetry install` step is also necessary to make sure the C-extension is available during development. If everything ran successfully, the following command should run without throwing exceptions:

    $ poetry run python -c "import pybind11_extension"

I've prepared a [sample project in GitHub](https://github.com/octavifs/poetry-pybind11-integration) with a working setup, following the steps described here. Hope you've found this useful and happy coding!
