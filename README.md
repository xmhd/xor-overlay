# STATUS #

# README #

This overlay contains packages for software that:

* aren't yet packaged for Gentoo Linux
* are missing features due to the maintainer not wishing to carry a minimal patchset
* does not have long-term-support releases
* require modification for being as compatible with musl
* unsupported-ish upstream

### Copyright ###

* Original ebuilds in this repository are copyrighted by the author
* Forked ebuilds are copyrighted by the original author to the date that they were forked, e.g. (C) Gentoo 2012 - 2020
  and then copyrighted 2020 - Present by the new maintainer
* All work in this repository is open source and licensed GPL v2 and can be used free of charge as long as the license
  is respected and the copyright headers remain preserved

### Installing ###

* Add an entry under repos.conf in portage with sync-type = git and sync-uri = $URL, and perform an emerge --sync
* There is no tested layman support, use repos.conf

### TLDR; Changelog for packages forked from main repositories ###

* Python - link-time-optmization and profile-guided-optimization support added to ebuilds
* sysvinit - Added fix to inittab to support shutting down containers from host
* All JetBrains software - up-to-date working releases
* nm-applet - Removed hard dependency on polkit as it is not required
* libsecret - Removed hard dependency on gnome-keyring and added USE flag to support multiple providers of
  FreeDesktop.org libsecret service (e.g. keepassx, gnome-keyring)
* gentoo-sources - Linux kernel sources with additional patches and optional compilation, module signing etc
* icecream - up-to-date releases
* OpenJDK - forked to add older OpenJDK versions and add musl support
* debianutils - removed gentoo-installkernel stuff from ebuild as we use Debian' installkernel script

### TLDR; Changelog for packages not in the main repositories ###

* ego - Configuration tool from Funtoo Linux by Daniel Robbins. Replaces eselect-profile from Gentoo Linux
* gcc - Refactored logic which will all reside inside the ebuild rather than toolchain.eclass, so that additional patch
  sets can be easily added etc
* DTrace - tracer from Solaris & BSD, supported in Oracle Linux and now Gentoo Linux
* MangoHUD - GUI overlay for displaying CPU + GPU temperatures, FPS etc during gaming.
* PyWal - Match your terminal font colours to your wallpaper.

### TLDR; Changelog for eclasses forked from main repositories ###

* flag-o-matic - don't strip stack-clash-protection and retpoline flags.

### TLDR; Changelog for profiles in this repository ###

* Funtoo Linux styled profiles (flavors, mix-ins etc).
* No support for prefix on Windows, MacOS etc.
* glibc and musl supported.
* Further system hardening.
* NO UCLIBC/-NG SUPPORT - move to musl.
* sysvinit+OpenRC supported as a first class citizens.
* eudev supported as a first class citizen.
* ZFS supported as a first class citizen.
* Sane defaults for desktop/workstation users.
* Link-time-optimization support.

### TODO: ###

* Toolchain work.
* OpenJDK.
* Profiles - continue expansion and further modularisation.
* Expand on hardening features/defaults.
* beadm - boot envrionment support for zfs users.
* profit??

### Who do I talk to? ###

* x0r/xaero on libera/OFTC, or message here.

### Anything else? ###

* Contributions welcome
