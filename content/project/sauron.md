---
title: "SAURON"
date: 2019-01-10T19:06:20+01:00
layout: 'about'
draft: false
---

## Automatic retinal disease detection

I partnered with Optretina, a leading ophthalmology telemedicine startup in Spain, to develop a new product for automated retinal disease detection based on deep learning. The idea was to leverage their medical expertise and retinal database with my technical knowledge to create new AI products that would help in the screening of retinal diseases. During my tenure there I lead the development of [Sauron and Jarvis](https://www.optretina.com/health-corporations/).

---

### Introduction
80% of blindness and visual impairment can be prevented if detected early enough. The main causes of blindness in the developed world are due to diseases such as AMD, diabetic retinopathy and glaucoma, all of which don't have symptoms until very late stages, but can be treated with good outcomes if detected early enough.

There are not enough retinal specialists worldwide to ensure that the population has direct access to them, but telemedicine and AI can help to improve the reach and bring down the costs of performing retinal screenings in the population at scale.

### Sauron
Sauron is a platform to train and deploy deep learning models for retinal disease detection. It detects the most common retinal pathologies: diabetic retinopathy, age macular degeneration, glaucomatous optic neuropathy and nevus.

I developed Sauron as a REST API, so it would be easy to leverage by other services, internal or external. The platform also has tools to label, train, evaluate and deploy algorithms, both new and retrained.

### Jarvis
Jarvis is an automated retinal screening application built on top of Sauron. The app takes digital fundus images taken from the retina of a patient, evaluates its quality, and then proceeds to generate an automated report with a diagnostic based on Sauron's output.

### Clinical trial results
[![paper abstract](/media/project/sauron/paper_abstract.png)](https://link.springer.com/article/10.1007/s00417-022-05653-2)
