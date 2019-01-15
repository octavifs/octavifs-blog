---
title: "LUCANODE"
date: 2019-01-10T19:06:20+01:00
layout: 'about'
draft: false
---

## Automatic lung cancer nodule detection

### Abstract
Lung cancer is both the deadliest and one of the most frequently diagnosed forms of the disease. The main cause for the low survivability of lung cancer is due to its lack of early symptoms, which are only detected in terminal stages of the disease. It has been demonstrated that performing screenings in high-risk population increased the survivability by 20% but detecting lung lesions in CT imaging is time consuming and highly dependent on the skill of the radiologist.

*lucanode* is an open source implementation of a computer-aided detection (CADe) system for lung cancer nodule detection (hence the name) that I developed as part of my Master’s thesis dissertation. Its aim is to provide assistance to radiologists for early diagnosis of lung cancer by detecting round abnormalities in the lung (nodules).

*lucanode* is divided into a 4 step pipeline:

- scan preprocessing
- lung segmentation
- nodule segmentation
- false positive reduction

For each step, there are multiple attempted approaches, which have been quantiﬁed and evaluated against one another. Finally, the system as a whole is compared against the state of the art following the approach established in the LUNA grand challenge, a public dataset of CT images aimed at detecting lung nodules.

### Lung cancer
![Cancer incidence and mortality statistics](/media/project/lucanode/intro_1.png)

![Lung cancer in total figures](/media/project/lucanode/intro_2.png)

![Usage of CT screening in lung cancer](/media/project/lucanode/intro_3.png)

### The pipeline
![lucanode pipeline](/media/project/lucanode/pipeline.png)

### Lung segmentation
![lucanode lung segmentation](/media/project/lucanode/lung_segmentation.png)

### Nodule segmentation
![lucanode nodule segmentation](/media/project/lucanode/nodule_segmentation_1.png)

![lucanode nodule segmentation](/media/project/lucanode/nodule_segmentation_2.png)

### False positive reduction
![lucanode false positive reduction](/media/project/lucanode/fp_reduction_1.png)

![lucanode false positive reduction](/media/project/lucanode/fp_reduction_2.png)

![lucanode false positive reduction](/media/project/lucanode/fp_reduction_3.png)

### Results\
![lucanode results](/media/project/lucanode/results_1.png)

![lucanode results](/media/project/lucanode/results_2.png)

![lucanode results](/media/project/lucanode/results_3.png)

![lucanode results](/media/project/lucanode/results_4.png)

### Available resources
Master thesis [pdf](/media/project/lucanode/tfm_lucanode.pdf).

Source code available on [GitHub](https://github.com/octavifs/lucanode).

Network weights available on [Google Drive](https://drive.google.com/drive/folders/1uH6QDOmOVJUcnsmAFDXa3lF61Exe-RQj?usp=sharing).
