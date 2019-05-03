---
title: "Thinkpad X1 Carbon 6th Gen (2018) on Ubuntu 19.04"
date: 2019-05-03T00:57:34+02:00
draft: false
---

This is my recipe to install Ubuntu 19.04 Disco Dingo on the Lenovo Thinkpad X1 Carbon 6th gen (2018). This guide should serve you as well for Ubuntu 18.04 LTS, but the newer kernel and GNOME on 19.04 offer better power management and HiDPI support.

<!-- more -->

![Thinkpad X1 Carbon 6th gen (2018)](/media/post/thinkpad-x1-carbon-6th-gen-2018-on-ubuntu-19-04/thinkpad_x1c_banner.jpg)

*Mugshot: The culprit behind this article, suspended*

The X1 Carbon is an excellent laptop for developers, and even though its Linux support is good, getting it to work perfectly still requires some tinkering. This topic has been covered already, but there've been improvements in hardware support over the last year that are not reflected on older articles. Hopefully this will serve as an up-to-date, streamlined version on how to set it up after installing Ubuntu.

This setup should leave the laptop fully working, except for the fingerprint reader, for which there are no available drivers. Everything else is 100% functional.


## BIOS config changes

We'll need to perform some changes on the BIOS to get the most of our Thinkpad. It's better to do so before installing Ubuntu itself, since secure boot needs to be disabled to perform the installation anyway. Here's the list:

    # Disable secure boot to install Ubuntu
    Security > Secure Boot: Disable

    # Set Sleep State to Linux to enable S3 suspend mode
    # This should be available on firmware version >= 1.30
    Config > Power > Sleep State: Set to Linux
    
    # Disable uneeded peripherals to save a few watts (optional)
    Security > I/O Port Access > Wireless WAN:       Disable
                               > Memory Card Slot:   Disable
                               > Fingerprint Reader: Disable


## Battery Life

After Ubuntu's install, you can add `tlp` to improve power management:

    sudo apt install tlp tlp-rdw acpi-call-dkms tp-smapi-dkms acpi-call-dkms

If you are keen on tracking the wattage your laptop is consuming, you should also try these tools:

    sudo apt install powertop s-tui

![s-tui monitoring power usage and temperature](/media/post/thinkpad-x1-carbon-6th-gen-2018-on-ubuntu-19-04/stui.png)

*s-tui monitoring power usage and temperature*


## CPU Throttling

X1 Carbon under Linux throttles the CPU below its TDP under load, robbing you of the extra *oomph* you paid top dollar for. Thankfully there is a [fix for that](https://github.com/erpalma/throttled). You'll have to install the following:

    sudo apt install git build-essential python3-dev libdbus-glib-1-dev libgirepository1.0-dev libcairo2-dev python3-venv python3-wheel
    git clone https://github.com/erpalma/lenovo-throttling-fix.git
    sudo ./lenovo-throttling-fix/install.sh

Also, you'll need to disable *thermald*, as it conflicts with the fix:

    sudo systemctl stop thermald.service
    sudo systemctl disable thermald.service
    sudo systemctl mask thermald.service

*lenovo-throttling-fix* also supports undervolting, which helps bringing temperatures down, improve battery life and increase performance. It also **DOES** make the system unstable, when performed too aggressively. The project [README](https://github.com/erpalma/throttled#Configuration) has extensive documentation on how to set it up, if you are so inclined.


## Suspend

Works out of the box once the BIOS *Sleep State* has been fixed.


## HiDPI support

If you have the WQHD screen and you find GNOME's 2x integer scaling too large for you, I've got an article dedicated to [fractional scaling HiDPI support on Ubuntu 19.04](/post/hidpi-support-on-ubuntu-19-04/).

TLDR: It works well, despite not being fully integrated in GNOME.


## Additional resources

- [Arch wiki](https://wiki.archlinux.org/index.php/Lenovo_ThinkPad_X1_Carbon_(Gen_6))
- [Thinkpad X1C on Ubuntu 18.04 (mensfeld)](https://mensfeld.pl/2018/05/lenovo-thinkpad-x1-carbon-6th-gen-2018-ubuntu-18-04-tweaks)
- [Thinkpad X1C on Ubuntu 18.04 (@hkdb)](https://medium.com/@hkdb/ubuntu-18-04-on-lenovo-x1-carbon-6g-d99d5667d4d5)
- [Lenovo Throttling fix](https://github.com/erpalma/throttled)
