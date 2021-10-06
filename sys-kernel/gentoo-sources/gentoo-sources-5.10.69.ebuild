# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit check-reqs mount-boot toolchain-funcs

DESCRIPTION="Linux kernel sources with some additional patches."
HOMEPAGE="https://kernel.org"

LICENSE="GPL-2"
KEYWORDS="amd64"

SLOT="${PV}"

RESTRICT="binchecks mirror strip"

# general kernel USE flags
IUSE="build-kernel clang compress debug doc +install-sources minimal symlink"
# optimize
IUSE="${IUSE} custom-cflags"
# security
IUSE="${IUSE} cet hardened +page-table-isolation pax +retpoline selinux sign-modules"
# initramfs
IUSE="${IUSE} btrfs firmware luks lvm mdadm microcode plymouth udev zfs"
# misc kconfig tweaks
IUSE="${IUSE} dtrace mcelog +memcg +numa"

BDEPEND="
	sys-devel/bc
	debug? ( dev-util/pahole )
	sys-devel/flex
	virtual/libelf
	virtual/yacc
"

RDEPEND="
	build-kernel? ( sys-kernel/dracut )
	btrfs? ( sys-fs/btrfs-progs )
	compress? ( sys-apps/kmod[lzma] )
	firmware? (
		sys-kernel/linux-firmware
	)
	luks? ( sys-fs/cryptsetup )
	lvm? ( sys-fs/lvm2 )
	mdadm? ( sys-fs/mdadm )
	mcelog? ( app-admin/mcelog )
	pax? ( app-misc/pax-utils )
	sign-modules? (
		dev-libs/openssl
		sys-apps/kmod
	)
	zfs? ( sys-fs/zfs )
"

REQUIRED_USE="
	!build-kernel? ( install-sources )
"

# linux kernel upstream
KERNEL_VERSION="${PV}"
KERNEL_EXTRAVERSION="-gentoo"
KERNEL_FULL_VERSION="${PV}${KERNEL_EXTRAVERSION}"
KERNEL_ARCHIVE="linux-${KERNEL_VERSION}.tar.xz"
KERNEL_UPSTREAM="https://cdn.kernel.org/pub/linux/kernel/v5.x/${KERNEL_ARCHIVE}"
KERNEL_CONFIG_UPSTREAM="https://git.alpinelinux.org/aports/plain/main/linux-lts"

SRC_URI="
	${KERNEL_UPSTREAM}

	x86? (
		minimal? ( ${KERNEL_CONFIG_UPSTREAM}/config-virt.x86 -> alpine-kconfig-virt-x86-${PV} )
		!minimal? ( ${KERNEL_CONFIG_UPSTREAM}/config-lts.x86 -> alpine-kconfig-x86-${PV} )
	)
	amd64? (
		minimal? ( ${KERNEL_CONFIG_UPSTREAM}/config-virt.x86_64 -> alpine-kconfig-virt-amd64-${PV} )
		!minimal? ( ${KERNEL_CONFIG_UPSTREAM}/config-lts.x86_64 -> alpine-kconfig-amd64-${PV} )
	)
	arm? (
		minimal? ( ${KERNEL_CONFIG_UPSTREAM}/config-virt.armv7 -> alpine-kconfig-virt-arm-${PV} )
		!minimal? ( ${KERNEL_CONFIG_UPSTREAM}/config-lts.armv7 -> alpine-kconfig-arm-${PV} )
	)
	arm64? (
		minimal? ( ${KERNEL_CONFIG_UPSTREAM}/config-virt.aarch64 -> alpine-kconfig-virt-arm64-${PV} )
		!minimal? ( ${KERNEL_CONFIG_UPSTREAM}/config-lts.aarch64 -> alpine-kconfig-arm64-${PV} )
	)
	ppc64? (
		minimal? ( ${KERNEL_CONFIG_UPSTREAM}/config-virt.ppc64le -> alpine-kconfig-virt-ppc64-${PV} )
		!minimal? ( ${KERNEL_CONFIG_UPSTREAM}/config-lts.ppc64le -> alpine-kconfig-ppc64-${PV} )
	)
"

S="$WORKDIR/linux-${KERNEL_VERSION}"

GENTOO_PATCHES_DIR="${FILESDIR}/${KERNEL_VERSION}/gentoo-patches"

# Gentoo Linux 'genpatches' patch set
GENTOO_PATCHES=(
	1500_XATTR_USER_PREFIX.patch
	1510_fs-enable-link-security-restrictions-by-default.patch
	2000_BT-Check-key-sizes-only-if-Secure-Simple-Pairing-enabled.patch
	2900_tmp513-Fix-build-issue-by-selecting-CONFIG_REG.patch
	2920_sign-file-patch-for-libressl.patch
	4567_distro-Gentoo-Kconfig.patch
	5000_shiftfs-ubuntu-20.04.patch
#	5010_enable-cpu-optimizations-universal.patch
)

PAX_PATCHES_DIR="${FILESDIR}/${KERNEL_VERSION}/pax-patches"

# TODO
PAX_PATCHES=(

)

DTRACE_PATCHES_DIR="${FILESDIR}/${KERNEL_VERSION}/dtrace-patches"

# TODO
DTRACE_PATCHES=(

)

tweak_config() {
	echo "$1" >> .config || die "failed to tweak \"$1\" in the kernel config"
}

get_certs_dir() {
	# find a certificate dir in /etc/kernel/certs/ that contains signing cert for modules.
	for subdir in $PF $P linux; do
		certdir=/etc/kernel/certs/$subdir
		if [[ -d $certdir ]]; then
			if [[ ! -e $certdir/signing_key.pem ]]; then
				eerror "$certdir exists but missing signing key; exiting."
				exit 1
			fi
			echo $certdir
			return
		fi
	done
}

pkg_pretend() {

	# perform sanity checks that only apply to source builds.
	if [[ ${MERGE_TYPE} != binary ]] && use build-kernel; then

		# Ensure we have enough disk space to compile
		CHECKREQS_DISK_BUILD="5G"
		check-reqs_pkg_setup
	fi

	# perform sanity checks that apply to both source + binary packages.
	if use build-kernel; then
		# check that our boot partition (if it exists) is mounted
		mount-boot_pkg_pretend

		# check that we have enough free space in the boot partition
		CHECKREQS_DISK_BOOT="64M"
		check-reqs_pkg_setup

		# a lot of hardware requires firmware
		if ! use firmware; then
			ewarn "sys-kernel/linux-firmware not found installed on your system."
			ewarn "This package provides firmware that may be needed for your hardware to work."
		fi
	fi

	# theoretically this should work on USE=x86 but it hasn't been tested.
	if use custom-cflags; then
		if ! use amd64; then
			die "USE=custom-cflags is currently amd64 + x86 only"
		fi
	fi
}

pkg_setup() {

	# will interfere with Makefile if set
	unset ARCH
	unset LDFLAGS
}

src_unpack() {

	# unpack the kernel sources to ${WORKDIR}
	unpack ${KERNEL_ARCHIVE}
}

src_prepare() {

	### PATCHES

	# apply gentoo patches
	einfo "Applying Gentoo Linux patches ..."
	for my_patch in ${GENTOO_PATCHES[*]}; do
		eapply "${GENTOO_PATCHES_DIR}/${my_patch}"
	done

	if use pax; then
		einfo "Applying PaX patches ..."
		for my_patch in ${PAX_PATCHES[*]}; do
			eapply "${PAX_PATCHES_DIR}/${my_patch}"
		done
	fi

	if use dtrace; then
		einfo "Applying DTrace patches ..."
		for my_patch in ${DTRACE_PATCHES[*]}; do
			eapply "${DTRACE_PATCHES_DIR}/${my_patch}"
		done
	fi

	if use custom-cflags; then
		eapply "${GENTOO_PATCHES_DIR}/5010_enable-cpu-optimizations-universal.patch"
	fi

	# append EXTRAVERSION to the kernel sources Makefile
	sed -i -e "s:^\(EXTRAVERSION =\).*:\1 ${KERNEL_EXTRAVERSION}:" Makefile || die "failed to append EXTRAVERSION to kernel Makefile"

	# todo: look at this, haven't seen it used in many cases.
	sed -i -e 's:#export\tINSTALL_PATH:export\tINSTALL_PATH:' Makefile || die "failed to fix-up INSTALL_PATH in kernel Makefile"

	# copy the kconfig file into the kernel sources tree
	cp "${DISTDIR}"/alpine-kconfig-* "${S}"/.config || die "failed to copy kconfig to kernel source tree"

	### TWEAK CONFIG ###

	if use custom-cflags; then

		# get the march from Portage
		MARCH="$(python -c "import portage; print(portage.settings[\"CFLAGS\"])" | sed 's/ /\n/g' | grep "march")"

		# if ${MARCH}=foo ...
		case ${MARCH} in
			*native)
				if grep -q "AuthenticAMD" /proc/cpuinfo; then
					tweak_config "CONFIG_MNATIVE_AMD=y"
				elif grep -q "GenuineIntel" /proc/cpuinfo; then
					tweak_config "CONFIG_MNATIVE_INTEL=y"
				fi
			;;
			*x86-64)
				tweak_config "CONFIG_GENERIC_CPU=y"
			;;
			*x86-64-v2)
				tweak_config "CONFIG_GENERIC_CPU2=y"
			;;
			*x86-64-v3)
				tweak_config "CONFIG_GENERIC_CPU3=y"
			;;
			*x86-64-v4)
				tweak_config "CONFIG_GENERIC_CPU4=y"
			;;
			*k8)
				tweak_config "CONFIG_MK8=y"
			;;
			*k8-sse3)
				tweak_config "CONFIG_MK8SSE3=y"
			;;
			*amdfam10)
				tweak_config "CONFIG_MK10=y"
			;;
			*barcelona)
				tweak_config "CONFIG_MBARCELONA=y"
			;;
			*btver1)
				tweak_config "CONFIG_MBOBCAT=y"
			;;
			*btver2)
				tweak_config "CONFIG_MJAGUAR=y"
			;;
			*bdver1)
				tweak_config "CONFIG_MBULLDOZER=y"
			;;
			*bdver2)
				tweak_config "CONFIG_MPILEDRIVER=y"
			;;
			*bdver3)
				tweak_config "CONFIG_MSTEAMROLLER=y"
			;;
			*bdver4)
				tweak_config "CONFIG_MEXCAVATOR=y"
			;;
			*znver1)
				tweak_config "CONFIG_MZEN=y"
			;;
			*znver2)
				tweak_config "CONFIG_MZEN2=y"
			;;
			*znver3)
				tweak_config "CONFIG_MZEN3=y"
			;;
			*core2)
				tweak_config "CONFIG_MCORE2=y"
			;;
			*atom | *bonnell)
				tweak_config "CONFIG_MATOM=y"
			;;
			*silvermont)
				tweak_config "CONFIG_MSILVERMONT=y"
			;;
			*goldmont)
				tweak_config "CONFIG_MGOLDMONT=y"
			;;
			*goldmont-plus)
				tweak_config "CONFIG_MGOLDMONTPLUS=y"
			;;
			*nehalem)
				tweak_config "CONFIG_MNEHALEM=y"
			;;
			*westmere)
				tweak_config "CONFIG_MWESTMERE=y"
			;;
			*sandybridge)
				tweak_config "CONFIG_MSANDYBRIDGE=y"
			;;
			*ivybridge)
				tweak_config "CONFIG_MIVYBRIDGE=y"
			;;
			*haswell)
				tweak_config "CONFIG_MHASWELL=y"
			;;
			*broadwell)
				tweak_config "CONFIG_MBROADWELL=y"
			;;
			*skylake)
				tweak_config "CONFIG_MSKYLAKE=y"
			;;
			*skylake-avx512)
				tweak_config "CONFIG_MSKYLAKEX=y"
			;;
			*cannonlake)
				tweak_config "CONFIG_MCANNONLAKE=y"
			;;
			*icelake-client)
				tweak_config "CONFIG_MICELAKE=y"
			;;
			*cascadelake)
				tweak_config "CONFIG_MCASCADELAKE=y"
			;;
			*cooperlake)
				tweak_config "CONFIG_MCOOPERLAKE=y"
			;;
			*tigerlake)
				tweak_config "CONFIG_MTIGERLAKE=y"
			;;
			*sapphirerapids)
				tweak_config "CONFIG_MSAPPHIRERAPIDS=y"
			;;
			*rocketlake)
				tweak_config "CONFIG_MROCKETLAKE=y"
			;;
			*alderlake)
				tweak_config "CONFIG_MALDERLAKE=y"
			;;
			*)
				tweak_config "CONFIG_GENERIC_CPU=y"
			;;
		esac
	fi

	# Do not configure Debian devs certificates
	tweak_config 'CONFIG_SYSTEM_TRUSTED_KEYS=""'

	# enable IKCONFIG so that /proc/config.gz can be used for various checks
	# TODO: Maybe not a good idea for USE=hardened, look into this...
	tweak_config "CONFIG_IKCONFIG=y"
	tweak_config "CONFIG_IKCONFIG_PROC=y"

	# enable kernel module compression
	if use compress-modules; then
		tweak_config "CONFIG_MODULE_COMPRESS=y"
		tweak_config "CONFIG_MODULE_COMPRESS_GZIP=n"
		tweak_config "CONFIG_MODULE_COMPRESS_XZ=y"
	else
		tweak_config "CONFIG_MODULE_COMPRESS=n"
	fi

	# only enable debugging symbols etc if USE=debug...
	if use debug; then
		tweak_config "CONFIG_DEBUG_INFO=y"
	else
		tweak_config "CONFIG_DEBUG_INFO=n"
	fi

	if use hardened; then

		tweak_config "CONFIG_GENTOO_KERNEL_SELF_PROTECTION=y"

		# disable gcc plugins on clang
		if use clang; then
			tweak_config "CONFIG_GCC_PLUGINS=n"
		fi

		# main hardening options complete... anything after this point is a focus on disabling potential attack vectors
		# i.e legacy drivers, new complex code that isn't yet proven, or code that we really don't want in a hardened kernel.

		# Kexec is a syscall that enables loading/booting into a new kernel from the currently running kernel.
		# This has been used in numerous exploits of various systems over the years, so we disable it.
		tweak_config 'CONFIG_KEXEC=n'
		tweak_config "CONFIG_KEXEC_FILE=n"
		tweak_config 'CONFIG_KEXEC_SIG=n'
	fi

	# mcelog is deprecated, but there are still some valid use cases and requirements for it... so stick it behind a USE flag for optional kernel support.
	if use mcelog; then
		tweak_config "CONFIG_X86_MCELOG_LEGACY=y"
	fi

	if use memcg; then
		tweak_config "CONFIG_MEMCG=y"
	else
		tweak_config "CONFIG_MEMCG=n"
	fi

	if use numa; then
		tweak_config "CONFIG_NUMA_BALANCING=y"
	else
		tweak_config "CONFIG_NUMA_BALANCING=n"
	fi

	if use pax; then
		tweak_config "CONFIG_PAX=y"
		tweak_config "CONFIG_PAX_NOEXEC=y"
		tweak_config "CONFIG_PAX_EMUTRAMP=y"
		tweak_config "CONFIG_PAX_MPROTECT=y"
	fi

	if use page-table-isolation; then
		tweak_config "CONFIG_PAGE_TABLE_ISOLATION=y"
		if use arm64; then
			tweak_config "CONFIG_UNMAP_KERNEL_AT_EL0=y"
		fi
	else
		tweak_config "CONFIG_PAGE_TABLE_ISOLATION=n"
		if use arm64; then
			tweak_config "CONFIG_UNMAP_KERNEL_AT_EL0=n"
		fi
	fi

	if use retpoline; then
		if use amd64 || use arm64 || use ppc64 || use x86; then
			tweak_config "CONFIG_RETPOLINE=y"
		elif use arm; then
			tweak_config "CONFIG_CPU_SPECTRE=y"
			tweak_config "CONFIG_HARDEN_BRANCH_PREDICTOR=y"
		fi
	else
		if use amd64 || use arm64 || use ppc64 || use x86; then
			tweak_config "CONFIG_RETPOLINE=n"
		elif use arm; then
			tweak_config "CONFIG_CPU_SPECTRE=n"
			tweak_config "CONFIG_HARDEN_BRANCH_PREDICTOR=n"
		fi

	fi

	# sign kernel modules via
	if use sign-modules; then
		certs_dir=$(get_certs_dir)
		tweak_config
		if [[ -z "$certs_dir" ]]; then
			eerror "No certs dir found in /etc/kernel/certs; aborting."
			die
		else
			einfo "Using certificate directory of $certs_dir for kernel module signing."
		fi
		tweak_config
		# turn on options for signing modules.
		# first, remove existing configs and comments:
		tweak_config 'CONFIG_MODULE_SIG=""'

		# now add our settings:
		tweak_config 'CONFIG_MODULE_SIG=y'
		tweak_config 'CONFIG_MODULE_SIG_FORCE=n'
		tweak_config 'CONFIG_MODULE_SIG_ALL=n'
		tweak_config 'CONFIG_MODULE_SIG_HASH="sha512"'
		tweak_config 'CONFIG_MODULE_SIG_KEY="${certs_dir}/signing_key.pem"'
		tweak_config 'CONFIG_SYSTEM_TRUSTED_KEYRING=y'
		tweak_config 'CONFIG_SYSTEM_EXTRA_CERTIFICATE=y'
		tweak_config 'CONFIG_SYSTEM_EXTRA_CERTIFICATE_SIZE="4096"'
		tweak_config "CONFIG_MODULE_SIG_SHA512=y"

		# print some info to warn user
		ewarn "This kernel will ALLOW non-signed modules to be loaded with a WARNING."
		ewarn "To enable strict enforcement, YOU MUST add module.sig_enforce=1 as a kernel boot"
		ewarn "parameter (to params in /etc/boot.conf, and re-run boot-update.)"
		echo
	fi

	# finally, apply any user patches
	eapply_user

	# get config into good state:
	yes "" | make oldconfig >/dev/null 2>&1 || die
	cp .config "${T}"/.config || die
	make -s mrproper || die "make mrproper failed"
}

src_configure() {

	if use build-kernel; then
		tc-export_build_env
		MAKEARGS=(
			V=1

			HOSTCC="$(tc-getBUILD_CC)"
			HOSTCXX="$(tc-getBUILD_CXX)"
			HOSTCFLAGS="${BUILD_CFLAGS}"
			HOSTLDFLAGS="${BUILD_LDFLAGS}"

			CROSS_COMPILE=${CHOST}-
			AS="$(tc-getAS)"
			CC="$(tc-getCC)"
			LD="$(tc-getLD)"
			AR="$(tc-getAR)"
			NM="$(tc-getNM)"
			STRIP=":"
			OBJCOPY="$(tc-getOBJCOPY)"
			OBJDUMP="$(tc-getOBJDUMP)"

			# we need to pass it to override colliding Gentoo envvar
			ARCH=$(tc-arch-kernel)
		)

		mkdir -p "${WORKDIR}"/build || die "failed to create build dir"
		cp "${T}"/.config "${WORKDIR}"/build/.config || die "failed to copy .config into build dir"

		local targets=( olddefconfig prepare modules_prepare scripts )

		# DTrace has an additional target for the ctf archive
		if use dtrace; then
			targets+=( ctf )
		fi

		emake O="${WORKDIR}"/build "${MAKEARGS[@]}" "${targets[@]}" || die "kernel configure failed"
	fi
}

src_compile() {

	if use build-kernel; then
		emake O="${WORKDIR}"/build "${MAKEARGS[@]}" all || "kernel build failed"
	fi
}

# this can likely be done a bit better
# TODO: create backups of kernel + initramfs if same ver exists?
install_kernel_and_friends() {

	install -d "${D}"/boot
	local kern_arch=$(tc-arch-kernel)

	cp "${WORKDIR}"/build/arch/${kern_arch}/boot/bzImage "${D}"/boot/vmlinuz-${KERNEL_FULL_VERSION} || die "failed to install kernel to /boot"
	cp "${T}"/.config "${D}"/boot/config-${KERNEL_FULL_VERSION} || die "failed to install kernel config to /boot"
	cp "${WORKDIR}"/build/System.map "${D}"/boot/System.map-${KERNEL_FULL_VERSION} || die "failed to install System.map to /boot"
}

src_install() {

	# create sources directory if required
	dodir /usr/src

	# copy kernel sources into place
	cp -a "${S}" "${D}"/usr/src/linux-${KERNEL_FULL_VERSION} || die "failed to install kernel sources"

	# change to installed kernel sources directory
	cd "${D}"/usr/src/linux-${KERNEL_FULL_VERSION}

	# clean-up kernel source tree
	make mrproper || die "failed to prepare kernel sources"

	# copy kconfig into place
	cp "${T}"/.config .config || die "failed to copy kconfig from ${TEMPDIR}"

	# if USE=-build-kernel - we're done.
	# The kernel source tree is left in an unconfigured state - you can't compile external kernel modules against it yet.
	# TODO: implement stripping down of leftover kernel sources to the absolute minimum if USE=-install-sources
	if use build-kernel; then

		# prepare the sources for real world use and external module building
		make prepare || die
		make modules_prepare || die
		make scripts || die

		# standard target for installing modules to /lib/modules/${KERNEL_FULL_VERSION}
		local targets=( modules_install )

		# ARM / ARM64 requires dtb
		if (use arm || use arm64); then
			targets+=( dtbs_install )
		fi

		emake O="${WORKDIR}"/build "${MAKEARGS[@]}" INSTALL_MOD_PATH="${ED}" INSTALL_PATH="${ED}/boot" "${targets[@]}"

		install_kernel_and_friends

		# module symlink fix-up:
		rm -rf "${D}"/lib/modules/${KERNEL_FULL_VERSION}/source || die "failed to remove old kernel source symlink"
		rm -rf "${D}"/lib/modules/${KERNEL_FULL_VERSION}/build || die "failed to remove old kernel build symlink"

		# Set-up module symlinks:
		ln -s /usr/src/linux-${KERNEL_FULL_VERSION} "${ED}"/lib/modules/${KERNEL_FULL_VERSION}/source || die "failed to create kernel source symlink"
		ln -s /usr/src/linux-${KERNEL_FULL_VERSION} "${ED}"/lib/modules/${KERNEL_FULL_VERSION}/build || die "failed to create kernel build symlink"

		# Fixes FL-14
		cp "${WORKDIR}/build/System.map" "${D}"/usr/src/linux-${KERNEL_FULL_VERSION}/ || die "failed to install System.map"
		cp "${WORKDIR}/build/Module.symvers" "${D}"/usr/src/linux-${KERNEL_FULL_VERSION}/ || die "failed to install Module.symvers"

		if use sign-modules; then
			for x in $(find "${D}"/lib/modules -iname *.ko); do
				# $certs_dir defined previously in this function.
				"${WORKDIR}"/build/scripts/sign-file sha512 $certs_dir/signing_key.pem $certs_dir/signing_key.x509 $x || die
			done
			# install the sign-file executable for future use.
			exeinto /usr/src/linux-${KERNEL_FULL_VERSION}/scripts
			doexe "${WORKDIR}"/build/scripts/sign-file
		fi
	fi
}

pkg_postinst() {

	# if USE=symlink...
	if use symlink; then
		# delete the existing symlink if one exists
		if [[ -h "${EROOT}"/usr/src/linux ]]; then
			rm "${EROOT}"/usr/src/linux || die "failed to delete existing /usr/src/linux symlink"
		fi
		# and now symlink the newly installed sources
		ewarn ""
		ewarn "WARNING... WARNING... WARNING"
		ewarn ""
		ewarn "/usr/src/linux symlink automatically set to linux-${KERNEL_FULL_VERSION}"
		ewarn ""
		ln -sf "${EROOT}"/usr/src/linux-${KERNEL_FULL_VERSION} "${EROOT}"/usr/src/linux || die "failed to create /usr/src/linux symlink"
	fi

	# if there's a modules folder for these sources, generate modules.dep and map files
	if [[ -d "${EROOT}"/lib/modules/${KERNEL_FULL_VERSION} ]]; then
		depmod -a ${KERNEL_FULL_VERSION} || die "failed to run depmod -a"
	fi

	# rebuild the initramfs on post_install
	if use build-kernel; then
		einfo ">>> Dracut: building initramfs"

		local dracut_args=(
			--no-hostonly
			--force
			--kver="${KERNEL_FULL_VERSION}"
			--kmoddir="${EROOT}/lib/modules/${KERNEL_FULL_VERSION}"
			--add="base"
			--omit="bootchart convertfs dmraid qemu qemu-net"
			$(usex btrfs "--add=btrfs" "--omit=btrfs" )
			$(usex compress "--compress=xz" "--no-compress" )
			$(usex debug "--stdlog=6" "--stdlog=1" )
			$(usex firmware "--fwdir=/lib/firmware" "" )
			$(usex luks "--add=crypt" "--omit=crypt" )
			$(usex lvm "--add=lvm --lvmconf" "--omit=lvm --nolvmconf" )
			$(usex mdadm "--add=mdraid --mdadmconf" "--omit=mdraid --nomdadmconf" )
			$(usex microcode "--early-microcode" "--no-early-microcode" )
			$(usex plymouth "--add=plymouth" "--omit=plymouth" )
			$(usex selinux "--add=selinux" "--omit=selinux" )
			$(usex systemd "" "" )
			$(usex udev "--add=udev-rules" "--omit=udev-rules" )
			$(usex zfs "--add=zfs" "--omit=zfs" )
		)

		dracut ${dracut_args[@]} "${EROOT}"/boot/initramfs-${KERNEL_FULL_VERSION} || die "failed to build initramfs"

		einfo ""
		einfo ">>> Dracut: Finished building initramfs"
	fi

	# warn about the issues with running a hardened kernel
	if use hardened; then
		ewarn "Hardened patches have been applied to the kernel and KCONFIG options have been set."
		ewarn "These KCONFIG options and patches change kernel behavior."
		ewarn "Changes include:"
		ewarn "Increased entropy for Address Space Layout Randomization"
		if ! use clang; then
			ewarn "GCC plugins"
		fi
		ewarn "Memory allocation"
		ewarn "... and more"
		ewarn ""
		if use pax; then
			ewarn "W^X (writable or executable) TODO"
			ewarn ""
		fi
		ewarn "These changes will stop certain programs from functioning"
		ewarn "e.g. VirtualBox, Skype"
		ewarn "Full information available in $DOCUMENTATION"
		ewarn ""
	fi
}
