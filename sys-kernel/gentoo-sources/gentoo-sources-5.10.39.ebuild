# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit check-reqs eutils mount-boot toolchain-funcs

DESCRIPTION="Linux kernel sources with some additional patches."
HOMEPAGE="https://kernel.org"

LICENSE="GPL-2"
KEYWORDS="~amd64"

SLOT="${PV}"

RESTRICT="binchecks strip mirror"

# general kernel USE flags
IUSE="build-kernel clang compress-modules debug +install-sources symlink"
# optimize
IUSE="${IUSE} custom-cflags"
# security
IUSE="${IUSE} hardened +page-table-isolation PaX +retpoline selinux sign-modules"
# initramfs
IUSE="${IUSE} btrfs e2fs firmware luks lvm mdadm microcode plymouth xfs zfs"
# misc kconfig tweaks
IUSE="${IUSE} mcelog"


BDEPEND="
	sys-devel/bc
	debug? ( dev-util/dwarves )
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
	PaX? ( app-misc/pax-utils )
	plymouth? (
		x11-libs/libdrm[libkms]
		sys-boot/plymouth[libkms,udev]
	)
	sign-modules? (
		|| ( dev-libs/openssl
		     dev-libs/libressl
		)
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

KERNEL_CONFIG_VERSION="5.10.28-1"
KERNEL_CONFIG_UPSTREAM="https://salsa.debian.org/kernel-team/linux/-/raw/debian/${KERNEL_CONFIG_VERSION}/debian/config"

SRC_URI="
	${KERNEL_UPSTREAM}

	${KERNEL_CONFIG_UPSTREAM}/config -> debian-kconfig-${PV}
	x86? (
		${KERNEL_CONFIG_UPSTREAM}/i386/config -> debian-kconfig-i386-${PV}
		${KERNEL_CONFIG_UPSTREAM}/i386/config.686 -> debian-kconfig-i686-${PV}
		${KERNEL_CONFIG_UPSTREAM}/i386/config.686-pae -> debian-kconfig-i686-pae-${PV}
		${KERNEL_CONFIG_UPSTREAM}/kernelarch-x86/config -> debian-kconfig-kernelarch-x86-${PV}
	)
	amd64? (
		${KERNEL_CONFIG_UPSTREAM}/amd64/config -> debian-kconfig-amd64-${PV}
		${KERNEL_CONFIG_UPSTREAM}/kernelarch-x86/config -> debian-kconfig-kernelarch-amd64-${PV}
	)
	arm? (
		${KERNEL_CONFIG_UPSTREAM}/armhf/config -> debian-kconfig-arm-${PV}
		${KERNEL_CONFIG_UPSTREAM}/armhf/config.armmp-lpae -> debian-kconfig-arm-lpae-${PV}
		${KERNEL_CONFIG_UPSTREAM}/kernelarch-arm/config -> debian-kconfig-kernelarch-arm-${PV}
	)
	arm64? (
		${KERNEL_CONFIG_UPSTREAM}/arm64/config -> debian-kconfig-arm64-${PV}
		${KERNEL_CONFIG_UPSTREAM}/kernelarch-arm/config -> debian-kconfig-kernelarch-arm64-${PV}
	)
	ppc? (
		${KERNEL_CONFIG_UPSTREAM}/powerpc/config.powerpc -> debian-kconfig-ppc-${PV}
		${KERNEL_CONFIG_UPSTREAM}/powerpc/config.powerpc-smp -> debian-kconfig-ppc-smp-${PV}
		${KERNEL_CONFIG_UPSTREAM}/kernelarch-powerpc/config -> debian-kconfig-kernelarch-ppc-${PV}
	)
	ppc64? (
		${KERNEL_CONFIG_UPSTREAM}/kernelarch-powerpc/config -> debian-kconfig-kernelarch-ppc64-${PV}
		${KERNEL_CONFIG_UPSTREAM}/kernelarch-powerpc/config-arch-64 -> debian-kconfig-kernelarch-64-${PV}
		${KERNEL_CONFIG_UPSTREAM}/kernelarch-powerpc/config-arch-64-le -> debian-kconfig-kernelarch-64-le-${PV}
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

# TODO: manage HARDENED_PATCHES and GENTOO_PATCHES
# can be managed in a git repository and packed into tar balls per version.

HARDENED_PATCHES_DIR="${FILESDIR}/${KERNEL_VERSION}/hardened-patches"

# 'linux-hardened' minimal patch set to compliment existing Kernel-Self-Protection-Project
HARDENED_PATCHES=(
	0001-make-DEFAULT_MMAP_MIN_ADDR-match-LSM_MMAP_MIN_ADDR.patch
	0002-enable-HARDENED_USERCOPY-by-default.patch
	0003-disable-HARDENED_USERCOPY_FALLBACK-by-default.patch
	0004-enable-SECURITY_DMESG_RESTRICT-by-default.patch
	0005-set-kptr_restrict-2-by-default.patch
	0006-enable-DEBUG_LIST-by-default.patch
	0007-enable-BUG_ON_DATA_CORRUPTION-by-default.patch
	0008-enable-ARM64_SW_TTBR0_PAN-by-default.patch
	0009-arm64-enable-RANDOMIZE_BASE-by-default.patch
	0010-enable-SLAB_FREELIST_RANDOM-by-default.patch
	0011-enable-SLAB_FREELIST_HARDENED-by-default.patch
	0012-disable-SLAB_MERGE_DEFAULT-by-default.patch
	0013-enable-FORTIFY_SOURCE-by-default.patch
	0014-enable-PANIC_ON_OOPS-by-default.patch
	0015-stop-hiding-SLUB_DEBUG-behind-EXPERT.patch
	0016-stop-hiding-X86_16BIT-behind-EXPERT.patch
	0017-disable-X86_16BIT-by-default.patch
	0018-stop-hiding-MODIFY_LDT_SYSCALL-behind-EXPERT.patch
	0019-disable-MODIFY_LDT_SYSCALL-by-default.patch
	0020-set-LEGACY_VSYSCALL_NONE-by-default.patch
	0021-stop-hiding-AIO-behind-EXPERT.patch
	0022-disable-AIO-by-default.patch
	0023-remove-SYSVIPC-from-arm64-x86_64-defconfigs.patch
	0024-disable-DEVPORT-by-default.patch
	0025-disable-PROC_VMCORE-by-default.patch
	0026-disable-NFS_DEBUG-by-default.patch
	0027-enable-DEBUG_WX-by-default.patch
	0028-disable-LEGACY_PTYS-by-default.patch
	0029-disable-DEVMEM-by-default.patch
	0030-enable-IO_STRICT_DEVMEM-by-default.patch
	0031-disable-COMPAT_BRK-by-default.patch
	0032-use-maximum-supported-mmap-rnd-entropy-by-default.patch
#	0033-enable-protected_-symlinks-hardlinks-by-default.patch
	0034-enable-SECURITY-by-default.patch
	0035-enable-SECURITY_YAMA-by-default.patch
	0036-enable-SECURITY_NETWORK-by-default.patch
	0037-enable-AUDIT-by-default.patch
	0038-enable-SECURITY_SELINUX-by-default.patch
	0039-enable-SYN_COOKIES-by-default.patch
	0040-enable-INIT_ON_ALLOC_DEFAULT_ON-by-default.patch
	0041-enable-INIT_ON_FREE_DEFAULT_ON-by-default.patch
	0042-kconfig-select-DEBUG_FS_ALLOW_NONE-by-default-if-DEB.patch
	0043-stop-hiding-SYSFS_SYSCALL-behind-EXPERT.patch
	0044-disable-SYSFS_SYSCALL-by-default.patch
	0045-stop-hiding-UID16-behind-EXPERT.patch
	0046-disable-UID16-by-default.patch
	0047-add-__read_only-for-non-init-related-usage.patch
	0048-make-sysctl-constants-read-only.patch
	0049-mark-kernel_set_to_readonly-as-__ro_after_init.patch
	0050-Revert-mark-kernel_set_to_readonly-as-__ro_after_ini.patch
	0051-mark-slub-runtime-configuration-as-__ro_after_init.patch
	0052-add-__ro_after_init-to-slab_nomerge-and-slab_state.patch
	0053-mark-kmem_cache-as-__ro_after_init.patch
	0054-mark-__supported_pte_mask-as-__ro_after_init.patch
	0055-mark-kobj_ns_type_register-as-only-used-for-init.patch
	0056-mark-open_softirq-as-only-used-for-init.patch
	0057-remove-unused-softirq_action-callback-parameter.patch
	0058-mark-softirq_vec-as-__ro_after_init.patch
	0059-mm-slab-trigger-BUG-if-requested-object-is-not-a-sla.patch
	0060-bug-on-kmem_cache_free-with-the-wrong-cache.patch
	0061-bug-on-PageSlab-PageCompound-in-ksize.patch
	0062-mm-add-support-for-verifying-page-sanitization.patch
	0063-slub-Extend-init_on_free-to-slab-caches-with-constru.patch
	0064-slub-Add-support-for-verifying-slab-sanitization.patch
	0065-slub-add-multi-purpose-random-canaries.patch
	0066-security-perf-Allow-further-restriction-of-perf_even.patch
	0067-enable-SECURITY_PERF_EVENTS_RESTRICT-by-default.patch
	0068-add-sysctl-to-disallow-unprivileged-CLONE_NEWUSER-by.patch
	0069-add-CONFIG-for-unprivileged_userns_clone.patch
	0070-add-kmalloc-krealloc-alloc_size-attributes.patch
	0071-add-vmalloc-alloc_size-attributes.patch
	0072-add-kvmalloc-alloc_size-attribute.patch
	0073-add-percpu-alloc_size-attributes.patch
	0074-add-alloc_pages_exact-alloc_size-attributes.patch
	0075-Add-the-extra_latent_entropy-kernel-parameter.patch
	0076-ata-avoid-null-pointer-dereference-on-bug.patch
	0077-sanity-check-for-negative-length-in-nla_memcpy.patch
	0078-add-page-destructor-sanity-check.patch
	0079-PaX-shadow-cr4-sanity-check-essentially-a-revert.patch
	0080-add-writable-function-pointer-detection.patch
	0081-support-overriding-early-audit-kernel-cmdline.patch
	0082-FORTIFY_SOURCE-intra-object-overflow-checking.patch
	0083-Revert-mm-revert-x86_64-and-arm64-ELF_ET_DYN_BASE-ba.patch
	0084-x86_64-move-vdso-to-mmap-region-from-stack-region.patch
	0085-x86-determine-stack-entropy-based-on-mmap-entropy.patch
	0086-arm64-determine-stack-entropy-based-on-mmap-entropy.patch
	0087-randomize-lower-bits-of-the-argument-block.patch
	0088-x86_64-match-arm64-brk-randomization-entropy.patch
	0089-support-randomizing-the-lower-bits-of-brk.patch
	0090-mm-randomize-lower-bits-of-brk.patch
	0091-x86-randomize-lower-bits-of-brk.patch
	0092-mm-guarantee-brk-gap-is-at-least-one-page.patch
	0093-x86-guarantee-brk-gap-is-at-least-one-page.patch
	0094-x86_64-bound-mmap-between-legacy-modern-bases.patch
	0095-restrict-device-timing-side-channels.patch
	0096-sysctl-expose-proc_dointvec_minmax_sysadmin-as-API-f.patch
	0097-usb-add-toggle-for-disabling-newly-added-USB-devices.patch
	0098-usb-implement-dedicated-subsystem-sysctl-tables.patch
	0099-hard-wire-legacy-checkreqprot-option-to-0.patch
	0100-security-tty-Add-owner-user-namespace-to-tty_struct.patch
	0101-security-tty-make-TIOCSTI-ioctl-require-CAP_SYS_ADMI.patch
	0102-enable-SECURITY_TIOCSTI_RESTRICT-by-default.patch
	0103-disable-unprivileged-eBPF-access-by-default.patch
	0104-enable-BPF-JIT-hardening-by-default-if-available.patch
	0105-enable-protected_-fifos-regular-by-default.patch
	0106-modpost-Add-CONFIG_DEBUG_WRITABLE_FUNCTION_POINTERS_.patch
	0107-mm-Fix-extra_latent_entropy.patch
	0108-add-CONFIG-for-unprivileged_userfaultfd.patch
	0109-slub-Extend-init_on_alloc-to-slab-caches-with-constr.patch
	0110-net-tcp-add-option-to-disable-TCP-simultaneous-conne.patch
	0111-dccp-ccid-move-timers-to-struct-dccp_sock.patch
	0112-Revert-dccp-don-t-free-ccid2_hc_tx_sock-struct-in-dc.patch
)

PAX_PATCHES_DIR="${FILESDIR}/${KERNEL_VERSION}/pax-patches"

# TODO
PAX_PATCHES=(
	0001-NOWRITEEXEC-and-PAX-features-MPROTECT-EMUTRAMP.patch
	0002-PAX_RANDKSTACK.patch
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
	if [[ ${MERGE_TYPE} != binary ]] && use build-kernel ; then

		# to run callback emerge we need to make sure a few FEATURES are disabled/enabled
		if has ebuild-locks ${FEATURES} || ! has parallel-install ${FEATURES} ; then
			die 'callback emerge for external module rebuilds requires FEATURES="-ebuild-locks parallel-install"'
		fi

		# Ensure we have enough disk space to compile
		CHECKREQS_DISK_BUILD="5G"
		check-reqs_pkg_setup
	fi

	# perform sanity checks that apply to both source + binary packages.
	if use build-kernel ; then
		# check that our boot partition (if it exists) is mounted
		mount-boot_pkg_pretend

		# a lot of hardware requires firmware
		if ! use firmware ; then
			ewarn "sys-kernel/linux-firmware not found installed on your system."
			ewarn "This package provides firmware that may be needed for your hardware to work."
		fi
	fi
}

pkg_setup() {
	# will interfere with Makefile if set
	unset ARCH; unset LDFLAGS
}

src_unpack() {

	# unpack the kernel sources to ${WORKDIR}
	unpack ${KERNEL_ARCHIVE} || die "failed to unpack kernel sources"

	# unpack the various kconfig files into a single file
	cat "${DISTDIR}"/debian-kconfig-* >> "${WORKDIR}"/debian-kconfig-${PV} || die "failed to unpack kconfig"
}

src_prepare() {

	### PATCHES

	# apply gentoo patches
	einfo "Applying Gentoo Linux patches ..."
	for my_patch in ${GENTOO_PATCHES[*]} ; do
		eapply "${GENTOO_PATCHES_DIR}/${my_patch}"
	done

	# conditionally apply hardening patches
	if use hardened ; then
		einfo "Applying hardening patches ..."
		for my_patch in ${HARDENED_PATCHES[*]} ; do
			eapply "${HARDENED_PATCHES_DIR}/${my_patch}"
		done
	fi

	if use PaX ; then
		einfo "Applying PaX patches ..."
		for my_patch in ${PAX_PATCHES[*]} ; do
			eapply "${PAX_PATCHES_DIR}/${my_patch}"
		done
	fi

	# append EXTRAVERSION to the kernel sources Makefile
	sed -i -e "s:^\(EXTRAVERSION =\).*:\1 ${KERNEL_EXTRAVERSION}:" Makefile || die "failed to append EXTRAVERSION to kernel Makefile"

	# todo: look at this, haven't seen it used in many cases.
	sed -i -e 's:#export\tINSTALL_PATH:export\tINSTALL_PATH:' Makefile || die "failed to fix-up INSTALL_PATH in kernel Makefile"

	# copy the kconfig file into the kernel sources tree
	cp "${WORKDIR}"/debian-kconfig-${PV} "${S}"/.config

	if use custom-cflags; then
		MARCH="$(python -c "import portage; print(portage.settings[\"CFLAGS\"])" | sed 's/ /\n/g' | grep "march")"
		if [ -n "$MARCH" ]; then
			sed -i -e 's/-mtune=generic/$MARCH/g' arch/x86/Makefile || die "Canna optimize this kernel anymore, captain!"
		fi
	fi

	### TWEAK CONFIG ###

	# this is horrible.... TODO: change the echo shite to sed

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

	if use hardened ; then
		# === GENERAL HARDENING OPTS
		# TODO: document these
		echo "CONFIG_AUDIT=y" >> .config
		echo "CONFIG_EXPERT=y" >> .config
		echo "CONFIG_SLUB_DEBUG=y" >> .config
		echo "CONFIG_SLAB_MERGE_DEFAULT=n" >> .config
		echo "CONFIG_SLAB_FREELIST_RANDOM=y" >> .config
		echo "CONFIG_SLAB_FREELIST_HARDENED=y" >> .config
		echo "CONFIG_SLAB_CANARY=y" >> .config
		echo "CONFIG_SHUFFLE_PAGE_ALLOCATOR=y" >> .config
		echo "CONFIG_RANDOMIZE_BASE=y" >> .config
		echo "CONFIG_RANDOMIZE_MEMORY=y" >> .config
		echo "CONFIG_HIBERNATION=n" >> .config
		echo "CONFIG_HARDENED_USERCOPY=y" >> .config
		echo "CONFIG_HARDENED_USERCOPY_FALLBACK=n" >> .config
		echo "CONFIG_FORTIFY_SOURCE=y" >> .config
		echo "CONFIG_STACKPROTECTOR=y" >> .config
		echo "CONFIG_STACKPROTECTOR_STRONG=y" >> .config
		echo "CONFIG_ARCH_MMAP_RND_BITS=32" >> .config
		echo "CONFIG_ARCH_MMAP_RND_COMPAT_BITS=16" >> .config
		echo "CONFIG_INIT_ON_FREE_DEFAULT_ON=y" >> .config
		echo "CONFIG_INIT_ON_ALLOC_DEFAULT_ON=y" >> .config
		echo "CONFIG_SLAB_SANITIZE_VERIFY=y" >> .config
		echo "CONFIG_PAGE_SANITIZE_VERIFY=y" >> .config

		# gcc plugins
		if ! use clang; then
			echo "CONFIG_GCC_PLUGINS=y" >> .config
			echo "CONFIG_GCC_PLUGIN_LATENT_ENTROPY=y" >> .config
			echo "CONFIG_GCC_PLUGIN_STRUCTLEAK=y" >> .config
			echo "CONFIG_GCC_PLUGIN_STRUCTLEAK_BYREF_ALL=y" >> .config
			echo "CONFIG_GCC_PLUGIN_STACKLEAK=y" >> .config
			echo "CONFIG_STACKLEAK_TRACK_MIN_SIZE=100" >> .config
			echo "CONFIG_STACKLEAK_METRICS=n" >> .config
			echo "CONFIG_STACKLEAK_RUNTIME_DISABLE=n" >> .config
			echo "CONFIG_GCC_PLUGIN_RANDSTRUCT=y" >> .config
			echo "CONFIG_GCC_PLUGIN_RANDSTRUCT_PERFORMANCE=n" >> .config
		fi

		# main hardening options complete... anything after this point is a focus on disabling potential attack vectors
		# i.e legacy drivers, new complex code that isn't yet proven, or code that we really don't want in a hardened kernel.

		# Kexec is a syscall that enables loading/booting into a new kernel from the currently running kernel.
		# This has been used in numerous exploits of various systems over the years, so we disable it.
		echo 'CONFIG_KEXEC=n' >> .config
		echo "CONFIG_KEXEC_FILE=n" >> .config
		echo 'CONFIG_KEXEC_SIG=n' >> .config
	fi

	# === END HARDENING OPTS

	# mcelog is deprecated, but there are still some valid use cases and requirements for it... so stick it behind a USE flag for optional kernel support.
	if use mcelog; then
		echo "CONFIG_X86_MCELOG_LEGACY=y" >> .config
	fi

	if use PaX ; then
		echo "CONFIG_PAX=y" >> .config
		echo "CONFIG_PAX_RANDKSTACK=y" >> .config
		echo "CONFIG_PAX_NOWRITEEXEC=y" >> .config
		echo "CONFIG_PAX_EMUTRAMP=y" >> .config
		echo "CONFIG_PAX_MPROTECT=y" >> .config
	fi

	if use page-table-isolation ; then
		echo "CONFIG_PAGE_TABLE_ISOLATION=y" >> .config
		if use arm64 ; then
			echo "CONFIG_UNMAP_KERNEL_AT_EL0=y" >> .config
		fi
	else
		echo "CONFIG_PAGE_TABLE_ISOLATION=n" >> .config
		if use arm64 ; then
			echo "CONFIG_UNMAP_KERNEL_AT_EL0=n" >> .config
		fi
	fi

	if use retpoline ; then
		if use amd64 || use arm64 || use ppc64 || use x86 ; then
			echo "CONFIG_RETPOLINE=y" >> .config
		elif use arm ; then
			echo "CONFIG_CPU_SPECTRE=y" >> .config
			echo "CONFIG_HARDEN_BRANCH_PREDICTOR=y" >> .config
		fi
	else
		if use amd64 || use arm64 || use ppc64 || use x86 ; then
			echo "CONFIG_RETPOLINE=n" >> .config
		elif use arm ; then
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

	# get config into good state:
	yes "" | make oldconfig >/dev/null 2>&1 || die
	cp .config "${T}"/.config || die
	make -s mrproper || die "make mrproper failed"

	# finally, apply any user patches
	eapply_user
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
		emake O="${WORKDIR}"/build "${MAKEARGS[@]}" olddefconfig || die "kernel configure failed"
		emake O="${WORKDIR}"/build "${MAKEARGS[@]}" modules_prepare || die "modules_prepare failed"
	fi
}

src_compile() {

	if use build-kernel; then
		emake O="${WORKDIR}"/build "${MAKEARGS[@]}" all || "kernel build failed"
	fi
}

src_install() {

	# TODO: Change to SANDBOX_WRITE=".." for installkernel writes
	# Disable sandbox
	export SANDBOX_ON=0

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
		installkernel "${KERNEL_FULL_VERSION}" "${WORKDIR}/build/arch/x86_64/boot/bzImage" "${WORKDIR}/build/System.map" "${EROOT}/boot"

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

	# we only want to force initramfs rebuild if != binary package
	if [[ ${MERGE_TYPE} != binary ]] && use build-kernel ; then

		# fakeroot so we can always generate device nodes i.e /dev/console
		# TODO: this will fail for -rN kernel revisions as kerneldir is hardcoded badly
		# temporarily remove fakeroot
		genkernel \
			--color \
			--makeopts="${MAKEOPTS}" \
			--logfile="/var/log/genkernel.log" \
			--cachedir="/var/cache/genkernel" \
			--tmpdir="/var/tmp/genkernel" \
			--cleanup \
			--kernel-config="/boot/config-${KERNEL_FULL_VERSION}" \
			--kerneldir="/usr/src/linux-${KERNEL_FULL_VERSION}" \
			--kernel-outputdir="/usr/src/linux-${KERNEL_FULL_VERSION}" \
			--check-free-disk-space-bootdir="64" \
			--all-ramdisk-modules \
			--callback="emerge --ask=n --color=y --usepkg=n --quiet-build=y @module-rebuild" \
			$(usex btrfs "--btrfs" "--no-btrfs") \
			$(usex debug "--loglevel=5" "--loglevel=1") \
			$(usex e2fs "--e2fsprogs" "--no-e2fsprogs") \
			$(usex firmware "--firmware" "--no-firmware") \
			$(usex luks "--luks" "--no-luks") \
			$(usex lvm "--lvm" "--no-lvm") \
			$(usex mdadm "--mdadm" "--no-mdadm") \
			$(usex mdadm "--mdadm-config=/etc/mdadm.conf" "") \
			$(usex microcode "--microcode-initramfs" "--no-microcode-initramfs") \
			$(usex xfs "--xfsprogs" "--no-xfsprogs") \
			$(usex zfs "--zfs" "--no-zfs") \
			initramfs || die "failed to build initramfs"
	fi

	# warn about the issues with running a hardened kernel
	if use hardened ; then
		ewarn "Hardened patches have been applied to the kernel and KCONFIG options have been set."
		ewarn "These KCONFIG options and patches change kernel behavior."
		ewarn "Changes include:"
		ewarn "Increased entropy for Address Space Layout Randomization"
		if ! use clang ; then
			ewarn "GCC plugins"
		fi
		ewarn "Memory allocation"
		ewarn "... and more"
		ewarn ""
		if use PaX ; then
			ewarn "W^X (writable or executable) TODO"
			ewarn "RANDKSTACK TODO"
			ewarn ""
		fi
		ewarn "These changes will stop certain programs from functioning"
		ewarn "e.g. VirtualBox, Skype"
		ewarn "Full information available in $DOCUMENTATION"
		ewarn ""
	fi
}
