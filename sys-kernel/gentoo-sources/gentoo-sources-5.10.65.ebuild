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
IUSE="build-kernel clang compress-modules debug +install-sources minimal symlink"
# optimize
IUSE="${IUSE} custom-cflags"
# security
IUSE="${IUSE} hardened +page-table-isolation pax +retpoline selinux sign-modules"
# initramfs
IUSE="${IUSE} btrfs e2fs firmware luks lvm mdadm microcode udev-rules xfs zfs"
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
	build-kernel? ( >=sys-kernel/genkernel-4.2.0 )
	btrfs? ( sys-fs/btrfs-progs )
	compress-modules? ( sys-apps/kmod[lzma] )
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

get_certs_dir() {
	# find a certificate dir in /etc/kernel/certs/ that contains signing cert for modules.
	for subdir in $PF $P linux; do
		certdir=/etc/kernel/certs/$subdir
		if [ -d $certdir ]; then
			if [ ! -e $certdir/signing_key.pem ]; then
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
	unset ARCH; unset LDFLAGS
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
	cp "${DISTDIR}"/alpine-kconfig-* "${S}"/.config

	### TWEAK CONFIG ###

	# this is horrible.... TODO: change the echo shite to sed

	if use custom-cflags; then

		# get the march from Portage
		MARCH="$(python -c "import portage; print(portage.settings[\"CFLAGS\"])" | sed 's/ /\n/g' | grep "march")"

		# if ${MARCH}=foo ...
		case ${MARCH} in
			*native)
				if grep -q "AuthenticAMD" /proc/cpuinfo; then
					echo "CONFIG_MNATIVE_AMD=y" >> .config
				elif grep -q "GenuineIntel" /proc/cpuinfo; then
					echo "CONFIG_MNATIVE_INTEL=y" >> .config
				fi
			;;
			*x86-64)
				echo "CONFIG_GENERIC_CPU=y" >> .config
			;;
			*x86-64-v2)
				echo "CONFIG_GENERIC_CPU2=y" >> .config
			;;
			*x86-64-v3)
				echo "CONFIG_GENERIC_CPU3=y" >> .config
			;;
			*x86-64-v4)
				echo "CONFIG_GENERIC_CPU4=y" >> .config
			;;
			*k8)
				echo "CONFIG_MK8=y" >> .config
			;;
			*k8-sse3)
				echo "CONFIG_MK8SSE3=y" >> .config
			;;
			*amdfam10)
				echo "CONFIG_MK10=y" >> .config
			;;
			*barcelona)
				echo "CONFIG_MBARCELONA=y" >> .config
			;;
			*btver1)
				echo "CONFIG_MBOBCAT=y" >> .config
			;;
			*btver2)
				echo "CONFIG_MJAGUAR=y" >> .config
			;;
			*bdver1)
				echo "CONFIG_MBULLDOZER=y" >> .config
			;;
			*bdver2)
				echo "CONFIG_MPILEDRIVER=y" >> .config
			;;
			*bdver3)
				echo "CONFIG_MSTEAMROLLER=y" >> .config
			;;
			*bdver4)
				echo "CONFIG_MEXCAVATOR=y" >> .config
			;;
			*znver1)
				echo "CONFIG_MZEN=y" >> .config
			;;
			*znver2)
				echo "CONFIG_MZEN2=y" >> .config
			;;
			*znver3)
				echo "CONFIG_MZEN3=y" >> .config
			;;
			*core2)
				echo "CONFIG_MCORE2=y" >> .config
			;;
			*atom | *bonnell)
				echo "CONFIG_MATOM=y" >> .config
			;;
			*silvermont)
				echo "CONFIG_MSILVERMONT=y" >> .config
			;;
			*goldmont)
				echo "CONFIG_MGOLDMONT=y" >> .config
			;;
			*goldmont-plus)
				echo "CONFIG_MGOLDMONTPLUS=y" >> .config
			;;
			*nehalem)
				echo "CONFIG_MNEHALEM=y" >> .config
			;;
			*westmere)
				echo "CONFIG_MWESTMERE=y" >> .config
			;;
			*sandybridge)
				echo "CONFIG_MSANDYBRIDGE=y" >> .config
			;;
			*ivybridge)
				echo "CONFIG_MIVYBRIDGE=y" >> .config
			;;
			*haswell)
				echo "CONFIG_MHASWELL=y" >> .config
			;;
			*broadwell)
				echo "CONFIG_MBROADWELL=y" >> .config
			;;
			*skylake)
				echo "CONFIG_MSKYLAKE=y" >> .config
			;;
			*skylake-avx512)
				echo "CONFIG_MSKYLAKEX=y" >> .config
			;;
			*cannonlake)
				echo "CONFIG_MCANNONLAKE=y" >> .config
			;;
			*icelake-client)
				echo "CONFIG_MICELAKE=y" >> .config
			;;
			*cascadelake)
				echo "CONFIG_MCASCADELAKE=y" >> .config
			;;
			*cooperlake)
				echo "CONFIG_MCOOPERLAKE=y" >> .config
			;;
			*tigerlake)
				echo "CONFIG_MTIGERLAKE=y" >> .config
			;;
			*sapphirerapids)
				echo "CONFIG_MSAPPHIRERAPIDS=y" >> .config
			;;
			*rocketlake)
				echo "CONFIG_MROCKETLAKE=y" >> .config
			;;
			*alderlake)
				echo "CONFIG_MALDERLAKE=y" >> .config
			;;
			*)
				echo "CONFIG_GENERIC_CPU=y" >> .config
			;;
		esac
	fi

	# Do not configure Debian devs certificates
	echo 'CONFIG_SYSTEM_TRUSTED_KEYS=""' >> .config

	# enable IKCONFIG so that /proc/config.gz can be used for various checks
	# TODO: Maybe not a good idea for USE=hardened, look into this...
	echo "CONFIG_IKCONFIG=y" >> .config
	echo "CONFIG_IKCONFIG_PROC=y" >> .config

	# enable kernel module compression
	if use compress-modules; then
		echo "CONFIG_MODULE_COMPRESS=y" >> .config
		echo "CONFIG_MODULE_COMPRESS_GZIP=n" >> .config
		echo "CONFIG_MODULE_COMPRESS_XZ=y" >> .config
	else
		echo "CONFIG_MODULE_COMPRESS=n" >> .config
	fi

	# only enable debugging symbols etc if USE=debug...
	if use debug; then
		echo "CONFIG_DEBUG_INFO=y" >> .config
	else
		echo "CONFIG_DEBUG_INFO=n" >> .config
	fi

	if use hardened; then

		echo "CONFIG_GENTOO_KERNEL_SELF_PROTECTION=y" >> .config

		# disable gcc plugins on clang
		if use clang; then
			echo "CONFIG_GCC_PLUGINS=n" >> .config
		fi

		# main hardening options complete... anything after this point is a focus on disabling potential attack vectors
		# i.e legacy drivers, new complex code that isn't yet proven, or code that we really don't want in a hardened kernel.

		# Kexec is a syscall that enables loading/booting into a new kernel from the currently running kernel.
		# This has been used in numerous exploits of various systems over the years, so we disable it.
		echo 'CONFIG_KEXEC=n' >> .config
		echo "CONFIG_KEXEC_FILE=n" >> .config
		echo 'CONFIG_KEXEC_SIG=n' >> .config
	fi

	# mcelog is deprecated, but there are still some valid use cases and requirements for it... so stick it behind a USE flag for optional kernel support.
	if use mcelog; then
		echo "CONFIG_X86_MCELOG_LEGACY=y" >> .config
	fi

	if use memcg; then
		echo "CONFIG_MEMCG=y" >> .config
	else
		echo "CONFIG_MEMCG=n" >> .config
	fi

	if use numa; then
		echo "CONFIG_NUMA_BALANCING=y" >> .config
	else
		echo "CONFIG_NUMA_BALANCING=n" >> .config
	fi

	if use pax; then
		echo "CONFIG_PAX=y" >> .config
		echo "CONFIG_PAX_NOEXEC=y" >> .config
		echo "CONFIG_PAX_EMUTRAMP=y" >> .config
		echo "CONFIG_PAX_MPROTECT=y" >> .config
	fi

	if use page-table-isolation; then
		echo "CONFIG_PAGE_TABLE_ISOLATION=y" >> .config
		if use arm64; then
			echo "CONFIG_UNMAP_KERNEL_AT_EL0=y" >> .config
		fi
	else
		echo "CONFIG_PAGE_TABLE_ISOLATION=n" >> .config
		if use arm64; then
			echo "CONFIG_UNMAP_KERNEL_AT_EL0=n" >> .config
		fi
	fi

	if use retpoline; then
		if use amd64 || use arm64 || use ppc64 || use x86; then
			echo "CONFIG_RETPOLINE=y" >> .config
		elif use arm; then
			echo "CONFIG_CPU_SPECTRE=y" >> .config
			echo "CONFIG_HARDEN_BRANCH_PREDICTOR=y" >> .config
		fi
	else
		if use amd64 || use arm64 || use ppc64 || use x86; then
			echo "CONFIG_RETPOLINE=n" >> .config
		elif use arm; then
			echo "CONFIG_CPU_SPECTRE=n" >> .config
			echo "CONFIG_HARDEN_BRANCH_PREDICTOR=n" >> .config
		fi

	fi

	# sign kernel modules via
	if use sign-modules; then
		certs_dir=$(get_certs_dir)
		echo
		if [ -z "$certs_dir" ]; then
			eerror "No certs dir found in /etc/kernel/certs; aborting."
			die
		else
			einfo "Using certificate directory of $certs_dir for kernel module signing."
		fi
		echo
		# turn on options for signing modules.
		# first, remove existing configs and comments:
		echo 'CONFIG_MODULE_SIG=""' >> .config

		# now add our settings:
		echo 'CONFIG_MODULE_SIG=y' >> .config
		echo 'CONFIG_MODULE_SIG_FORCE=n' >> .config
		echo 'CONFIG_MODULE_SIG_ALL=n' >> .config
		echo 'CONFIG_MODULE_SIG_HASH="sha512"' >> .config
		echo 'CONFIG_MODULE_SIG_KEY="${certs_dir}/signing_key.pem"' >> .config
		echo 'CONFIG_SYSTEM_TRUSTED_KEYRING=y' >> .config
		echo 'CONFIG_SYSTEM_EXTRA_CERTIFICATE=y' >> .config
		echo 'CONFIG_SYSTEM_EXTRA_CERTIFICATE_SIZE="4096"' >> .config
		echo "CONFIG_MODULE_SIG_SHA512=y" >> .config

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

	# prepare for real-world use and 3rd-party module building:
	make mrproper || die "failed to prepare kernel sources"

	# copy kconfig into place
	cp "${T}"/.config .config || die "failed to copy kconfig from ${TEMPDIR}"

	# if we didn't USE=build-kernel - we're done.
	# The kernel source tree is left in an unconfigured state - you can't compile 3rd-party modules against it yet.
	# TODO: implement stripping down of leftover kernel sources to the absolute minimum if USE=-install-sources
	if use build-kernel; then
		make prepare || die
		make modules_prepare || die
		make scripts || die

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
			rm "${EROOT}"/usr/src/linux
		fi
		# and now symlink the newly installed sources
		ewarn ""
		ewarn "WARNING... WARNING... WARNING"
		ewarn ""
		ewarn "/usr/src/linux symlink automatically set to linux-${KERNEL_FULL_VERSION}"
		ewarn ""
		ln -sf "${EROOT}"/usr/src/linux-${KERNEL_FULL_VERSION} "${EROOT}"/usr/src/linux
	fi

	# if there's a modules folder for these sources, generate modules.dep and map files
	if [[ -d "${EROOT}"/lib/modules/${KERNEL_FULL_VERSION} ]]; then
		depmod -a ${KERNEL_FULL_VERSION}
	fi

	# rebuild the initramfs on post_install
	if use build-kernel; then

		# setup dirs for genkernel
		mkdir -p "${WORKDIR}"/genkernel/{tmp,cache,log}

		genkernel \
			--color \
			--makeopts="${MAKEOPTS}" \
			--logfile="${WORKDIR}/genkernel/log/genkernel.log" \
			--cachedir="${WORKDIR}/genkernel/cache" \
			--tmpdir="${WORKDIR}/genkernel/tmp" \
			--kernel-config="/boot/config-${KERNEL_FULL_VERSION}" \
			--kerneldir="/usr/src/linux-${KERNEL_FULL_VERSION}" \
			--kernel-outputdir="/usr/src/linux-${KERNEL_FULL_VERSION}" \
			--all-ramdisk-modules \
			--busybox \
			$(usex btrfs "--btrfs" "--no-btrfs") \
			$(usex debug "--loglevel=5" "--loglevel=1") \
			$(usex e2fs "--e2fsprogs" "--no-e2fsprogs") \
			$(usex firmware "--firmware" "--no-firmware") \
			$(usex luks "--luks" "--no-luks") \
			$(usex lvm "--lvm" "--no-lvm") \
			$(usex mdadm "--mdadm" "--no-mdadm") \
			$(usex mdadm "--mdadm-config=/etc/mdadm.conf" "") \
			$(usex microcode "--microcode-initramfs" "--no-microcode-initramfs") \
			$(usex udev-rules "--udev-rules" "--no-udev-rules") \
			$(usex xfs "--xfsprogs" "--no-xfsprogs") \
			$(usex zfs "--zfs" "--no-zfs") \
			initramfs || die "failed to build initramfs"
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
