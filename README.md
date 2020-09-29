# README #

This overlay contains packages for software that:

* aren't in the Gentoo/Funtoo repositories at all.
* aren't as up-to-date as I would like.
* aren't maintained to a sufficient standard in the main repositories.
* are missing critical features due to the maintainer not wishing to carry a minimal patchset.
* does not have long-term-support releases (e.g. lxd, LibreOffice).
* unsupported-ish upstream, but will be around in the enterprise for a long time to come yet (read: python2).

This overlay will eventually (tm) provide users with the ability to create a DISA STIG compliant Gentoo/Funtoo Linux based system.
And will also include software used for supporting hardware (printers, CAC keys, and so on) used within enterprise/government/DoD.

### Copyright ###

* Original ebuilds in this repository are copyrighted by the author.
* Forked ebuilds are copyrighted by the original author to the date that they were forked, e.g. (C) Gentoo 2012 - 2020 and then copyrighted 2020 - Present by the new maintainer.
* All work in this repository is open source and licensed GPL v2 and can be used free of charge as long as the license is respected and the copyright headers remain preserved.

### Installing ###

* Add an entry under repos.conf in portage with sync-type = git and sync-uri = $URL, and perform an emerge --sync.
* There is no tested layman support, use repos.conf.

### TLDR; Changelog for packages forked from main repositories ###

* Python 2 - Maintained for legacy support.
* Python - link-time-optmization and profile-guided-optimization support added to ebuilds.
* sysvinit - Added fix to inittab to support shutting down containers from host.
* OpenRC - added support for mounting systemd cgroups for compatibility with software which hard depends on said cgroups.
* All JetBrains software - up-to-date working releases.
* nm-applet - Removed hard dependency on polkit as it is not required.
* libsecret - Removed hard dependency on gnome-keyring and added USE flag to support multiple providers of FreeDesktop.org libsecret service (e.g. keepassx, gnome-keyring).
* linux-sources - Added additional kernel sources to satisfy virtual/linux-sources dependency.
* icecream - up-to-date releases.
* Clang - some fixes with new CMAKE config options.
* libcxx - Re-added libcxxrt as an alternative to libcxxabi.
* OpenJDK - forked to add older OpenJDK versions and remove some java-pkg setup from ebuild as this overlay will not be building java files from source, rather installing the jar files to /usr/share/java.
*           Only OpenJDK (or other JVM variants, e.g. GraalVM, Amazon Corretto, Azure Zulu) will benefit from being source built.
* debianutils - removed gentoo-installkernel stuff from ebuild as we use Debian' installkernel script.

### TLDR; Changelog for packages not in the main repositories ###

* Ego - Configuration tool from Funtoo Linux by Daniel Robbins. Replaces eselect-profile from Gentoo Linux.
* GCC - Re-written logic, further TODO.
* DTrace - tracer from Solaris & BSD, supported in Oracle Linux and now *too Linux.
* Eclipse Java IDE (including enterprise edition).
* Netbeans IDE - IDE formerly by Sun, now under Apache.
* Various packages for CAC key support.
* Various packages for PKCS11 support (including pam modules).
* OpenRGB - Open source software for customising RGB LEDs on hardware.
* MangoHUD - GUI overlay for displaying CPU + GPU temperatures, FPS etc during gaming.
* PyWal - Match your terminal font colours to your wallpaper.

### TLDR; Changelog for eclasses forked from main repositories ###

* flag-o-matic - don't strip stack-clash-protection and retpoline flags.

### TLDR; Changelog for eclasses not in the main repoositories ###

* toolchain-enable - automatically set active gcc to the latest emerged gcc.
* toolchain-gcc - WIP eclass to move as much gcc ebuild logic to eclass.

### TLDR; Changelog for profiles in this repository ###
* Funtoo Linux styled profiles (flavors, mix-ins etc).
* No support for prefix on Windows, MacOS etc.
* glibc and musl supported.
* Further system hardening.
* NO UCLIBC/-NG SUPPORT - move to musl.
* sysvinit+OpenRC supported as a first class citizens.
* eudev supported as a first class citizen.
* systemd supported for those who wish to use it.
* S6, runit and other init systems not supported.
* LibreSSL supported as a first class citizen.
* ZFS supported as a first class citizen.
* Sane defaults for desktop/workstation users.
* Link-time-optimization support.
* Clang/LLVM as a system compiler support.

### TODO: ###
* Continue STIG work.
* Toolchain work.
* OpenJDK - legacy versions and removal of all from-source Java support as it's mostly broken and little to no gain building anything other than the JVM from source.
* Profiles - continue expansion and further modularisation.
* Cockpit - import from RHEL and add sysvinit+OpenRC support.
* mdev/static-dev support???
* Expand Clang/LLVM system compiler mix-in.
* Expand on hardening features/defaults.
* beadm - boot envrionment support for zfs users.
* profit??

### Who do I talk to? ###

* x0r/xaero on freenode, or message here.

### Anything else? ###

* Contributions welcome
