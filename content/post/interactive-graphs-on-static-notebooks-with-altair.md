---
title: "Interactive Graphs on Static Notebooks With Altair"
date: 2019-06-04T16:58:54+02:00
draft: false
---

Do you like using Jupyter notebooks to explore your data but feel that it looks raw to be presentation worthy? Would you like being able to share interactive visualizations to colleagues and stakeholders with minimal fuss? In this post I'll show my approach to generating static reports with interactive plots. Powered by Altair and nbconvert.

<!--more-->

Many times, when performing data analysis on my notebooks, I've wished it were easier to share interactive visualizations with colleagues and stakeholders. Usually, libraries capable of generating interactive views only display statically outside of the notebook environment, if at all. And setting up a proper interactive data visualization platform feels like it would kill my velocity. In short, I wish for a solution that lets me iterate fast, is able to generate fancy interactive plots and can be self-contained into an easy to distribute HTML file.

These last few months I've been using [Altair](https://altair-viz.github.io/index.html) as my goto library for data visualization in python. Altair provides a declarative API to create data visualizations that mesh well with pandas dataframes, can perform data aggregations easily, has good aesthetics and renders on the client side, which enables interactivity. For those of you interested in knowing more about its design principles and capabilities feel free to check these resources:

- [An Introduction to Altair](https://vallandingham.me/altair_intro.html)
- [Exploratory Data Visualisation with Altair](https://medium.com/analytics-vidhya/exploratory-data-visualisation-with-altair-b8d85494795c)
- [Altair Example Gallery](https://altair-viz.github.io/gallery/index.html)

Altair integrates natively with [jupyter lab](https://jupyterlab.readthedocs.io/en/stable/) but charts do not render when the HTML is exported. This is because the necessary client-side dependencies are missing. While discouraging, it is still too early to give up. Thanks to [nbconvert](https://nbconvert.readthedocs.io/en/latest/) we can generate custom export templates, so we could augment the HTML exporter with the necessary libraries for Altair to work.

I've created a [gist](https://gist.github.com/octavifs/c19564c477e51b4ddd818756389e705e) with the modified template, example notebook and requirements. Also, it is only fair to mention [this github issue](https://github.com/altair-viz/altair/issues/329) which I've used as basis for this workaround. My version of the template should be compatible with both Altair *2.X* and *3.X*.

Once you've downloaded [nbconvert_altair_hidecode.tpl](https://gist.github.com/octavifs/c19564c477e51b4ddd818756389e705e#file-nbconvert_altair_hidecode-tpl) and [altair_static_interactive.ipynb](https://gist.github.com/octavifs/c19564c477e51b4ddd818756389e705e#file-altair_static_interactive-ipynb) you can generate the static HTML by running:

    jupyter nbconvert --to html \
        --template  nbconvert_altair_hidecode.tpl \
        altair_static_interactive.ipynb

This will generate an HTML report like [this one](/static/interactive-graphs-on-static-notebooks-with-altair/altair_static_interactive.html). Heck, you can even embed it into another page with an `<iframe>`. Look!

<iframe
    src="/static/interactive-graphs-on-static-notebooks-with-altair/altair_static_interactive.html"
    style="border:none; width:100%"
    onload="this.style.height=(this.contentDocument.body.scrollHeight + 10) +'px';"
>
</iframe>

An extra bit of magic I've built into the template is the functionality to hide code cells. Adding the tag `hidecode` to a cell will skip rendering the input, while preserving the output. Especially useful if you need a cleaned up version for decision makers.

Hopefully you'll find some of these ideas a useful addition to your data analysis toolset. As this field is very much in its infancy, we are still figuring out the workflows and tooling to perform our job effectively. And I believe that facilitating the distribution of good visualizations will be a step towards that direction.
