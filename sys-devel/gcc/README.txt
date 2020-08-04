=== INTRODUCTION ===

This is a 'simplified' gcc ebuild.

This ebuild is free from toolchain.eclass and will contain all logic for gcc (other than multilib, toolchain-funcs,
flag-o-matic etc) inside the ebuild, while being version specific. This will be repeated for all gcc versions.

This will allow more granular control over gcc (e.g. patches applied, USE configuration, bundled math-libs if desired).

gcc-10.2.0 is currently the master ebuild and is undergoing work at present (though almost 'complete'). Once complete
the new ebuild will be backported to previous versions of gcc allowing all previous versions to be installed and used.

My present intention is to add support to gcc-config allowing multiple compilers to be set, i.e:

 [1] x86_64-pc-linux-gnu-8.4.0 [ada]
 [2] x86_64-pc-linux-gnu-9.3.0 [cuda]
 [3] x86_64-pc-linux-gnu-10.2.0 [system]
 [4] x86_64-pc-linux-gnu-11.0.0 [user]

A similar working to java-config in Gentoo Linux based systems. This would allow pegging the system compiler to a recent
gcc version for setting a minimum scope of CFLAGS and features to build with (e.g. retpolines and stack clash protection),
while still allowing users to install legacy versions (i.e gcc 2.x or gcc 3.x) without giving them the ability to hose
their system by using said legacy gcc as a system compiler, without explicitly setting I_KNOW_WHAT_I_AM_DOING=y.

Similar idea for CUDA - while the system compiler may be pegged at a certain release, end users may have workloads
that are targetted to a specific CUDA compiler, so allowing this in a seamless manner would be ideal.


=== WHAT WORKS? ===

* All of Gentoo Linux gcc patches applied, hardened specific patches controlled via USE flags
* All USE flags currently work
* Granular hardening options (e.g. pie, ssp, link_now, stack_clash_protection, fortify_source)
* Cross compiler support via crossdev
* LTO and PGO with associated bootstraps


=== CROSSDEV ===

* TODO: automate setup of crossdev overlay locally


=== TODO ===

* Update ebuild to EAPI 7
* ADA support - WIP
* Identify and integrate relevant patches from Debian
* Bundled math-libs? possibly even binutils? I prefer to control these package versions via profile
* Patch default building of userspace retpolines and add a retpoline USE flag