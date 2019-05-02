---
title: "Thinkpad X1c 6th Gen Ubuntu 19 04"
date: 2019-05-01T23:59:57+02:00
draft: true
---

This is my recipe to setup my Thinkpad X1 Carbon 6th generation (2018) with Ubuntu 19.04. Special emphasis made on configuring Ubuntu with HiDPI support.

<!--more-->

Installing Ubuntu on the X1 Carbon is mostly an uneventful affair, but some quirks require more tinkering than necessary to get the best out of your hardware. There are very informative posts on this topic already (see [1] and [2]) but the information has become a bit disjointed and they do gloss over the HiDPI support, which in 18.04 is poor.

[1]: https://mensfeld.pl/2018/05/lenovo-thinkpad-x1-carbon-6th-gen-2018-ubuntu-18-04-tweaks/#Battery
[2]: https://medium.com/@hkdb/ubuntu-18-04-on-lenovo-x1-carbon-6g-d99d5667d4d5

Things that don't work:
- MicroSD card reader
- Fingerprint reader

Everything else is working. USB-C, HDMI output, USB, the touchpad, keyboard, keyboard shortcuts, keyboard backlight, camera, etc.

## BIOS config changes
I'm assuming that you'll be using your laptop with Ubuntu only. No more windows blasphemy.

Settings
    Suspend to S3

Security
    no MicroSD
    no Fingerprint


## Battery life
