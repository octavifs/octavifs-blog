---
title: "UBIMIND"
date: 2019-01-10T19:06:20+01:00
layout: 'about'
draft: false
---

## EEG controlled wheelchair

UBIMIND is R&D demo funded by Everis in partnership with Universitat Pompeu Fabra. The project aims to demonstrate the viability of Brain Computer Interfaces to control physical objects such as wheelchairs. The goal of the project is to improve the autonomy of people with neurodegenerative disorders, such as ALS.

{{< youtube "f08avWK_0vU" >}}

---

I worked as part of University's Pompeu Fabra Medtech group in assisting Everis with the data acquisition and signal processing aspects of the project.

The project was developed on top of the [Emotiv EEG headset](https://www.emotiv.com/epoc-x/) platform, which provides a user-friendly EEG headset for research and personal purposes.

The main efforts of the project were divided in 3 blocks:

- **Ubitrainer:** Automate data acquisition through an Electron app. It connected to the headset, guided the user through a training process, and prepared the data to feed the models for training.
- **SSVEP signal processing:** Creation of the SSVEP signal processing code and the machine learning models to predict actions based on the training data.
- **Ubiengine:** Online processor of EEG signals which employed the models prepared in the previous step to transform the EEG input of the headset into discrete actions that could be used as input for a wheelchair or videogame.

![ubimind architecture](/media/project/ubimind/ubimind_architecture.png "Ubimind overall architecture")
