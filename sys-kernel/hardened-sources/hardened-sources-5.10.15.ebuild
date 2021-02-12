# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit check-reqs eutils mount-boot toolchain-funcs

DESCRIPTION="Linux kernel sources with some optional patches."
HOMEPAGE="https://kernel.org"

LICENSE="GPL-2"
KEYWORDS="x86 amd64 arm arm64"

SLOT="${PV}"

RESTRICT="binchecks strip mirror"

IUSE="binary btrfs clang custom-cflags debug dmraid dtrace ec2 firmware hardened iscsi luks lvm mcelog mdadm microcode multipath nbd nfs plymouth selinux sign-modules symlink systemd wireguard zfs"

BDEPEND="
	sys-devel/bc
	debug? ( dev-util/dwarves )
	virtual/libelf
"

DEPEND="
	binary? ( sys-kernel/dracut )
	btrfs? ( sys-fs/btrfs-progs )
	dtrace? (
	    dev-util/dtrace-utils
	    dev-libs/libdtrace-ctf
	)
	firmware? (
		sys-kernel/linux-firmware
	)
	luks? ( sys-fs/cryptsetup )
	lvm? ( sys-fs/lvm2 )
	mdadm? ( sys-fs/mdadm )
	mcelog? ( app-admin/mcelog )
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
	systemd? ( sys-apps/systemd )
	wireguard? ( virtual/wireguard )
	zfs? ( sys-fs/zfs )
"

# linux kernel upstream
KERNEL_VERSION="5.10.15"
KERNEL_ARCHIVE="linux-${KERNEL_VERSION}.tar.xz"
KERNEL_UPSTREAM="https://cdn.kernel.org/pub/linux/kernel/v5.x/${KERNEL_ARCHIVE}"
KERNEL_EXTRAVERSION="-hardened"

KERNEL_CONFIG_UPSTREAM="https://salsa.debian.org/kernel-team/linux/-/raw/debian/5.10.13-1/debian/config"

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
        ${KERNEL_CONFIG_UPSTREAM}/kernelarch-x86/config -> debian-kconfig-kernelarch-x86-${PV}
    )
    arm64? (
        ${KERNEL_CONFIG_UPSTREAM}/arm64/config -> debian-kconfig-arm64-${PV}
        ${KERNEL_CONFIG_UPSTREAM}/kernelarch-arm/config -> debian-kconfig-kernelarch-arm-${PV}
    )
"

S="$WORKDIR/linux-${KERNEL_VERSION}"

GENTOO_PATCHES_DIR="${FILESDIR}/${KERNEL_VERSION}/gentoo-patches"

# Gentoo Linux 'genpatches' patch set
# 1510_fs-enable-link-security-restrctions-by-default.patch is already provided in hardened patches
# 4567_distro-Gentoo-Kconfiig TODO?
GENTOO_PATCHES=(
    1500_XATTR_USER_PREFIX.patch
#    1510_fs-enable-link-security-restrictions-by-default.patch
    2000_BT-Check-key-sizes-only-if-Secure-Simple-Pairing-enabled.patch
    2900_tmp513-Fix-build-issue-by-selecting-CONFIG_REG.patch
    2920_sign-file-patch-for-libressl.patch
#    4567_distro-Gentoo-Kconfig.patch
    5000_shiftfs-ubuntu-20.04.patch
)

# TODO: manage HARDENED_PATCHES and GENTOO_PATCHES
# can be managed in a git repository and packed into tar balls per version.

HARDENED_PATCHES_DIR="${FILESDIR}/${KERNEL_VERSION}/hardened-patches"

# 'linux-hardened' minimal patch set to compliment existing Kernel-Self-Protection-Project
# 0033-enable-protected_-symlinks-hardlinks-by-default.patch
# 0066-security-perf-Allow-further-restriction-of-perf_even.patch
# 0068-add-sysctl-to-disallow-unprivileged-CLONE_NEWUSER-by.patch
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
    0033-enable-protected_-symlinks-hardlinks-by-default.patch
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

DTRACE_PATCHES_DIR="${FILESDIR}/${KERNEL_VERSION}/dtrace-patches"

DTRACE_PATCHES=(
    0001-ctf-generate-CTF-information-for-the-kernel.patch
    0002-kallsyms-introduce-new-proc-kallmodsyms-including-bu.patch
    0003-waitfd-new-syscall-implementing-waitpid-over-fds.patch
    0004-dtrace-core-and-x86.patch
    0005-dtrace-modular-components-and-x86-support.patch
    0006-dtrace-systrace-provider-core-components.patch
    0007-dtrace-systrace-provider.patch
    0008-dtrace-sdt-provider-core-components.patch
    0009-dtrace-sdt-provider-for-x86.patch
#    0010-dtrace-profile-provider-and-test-probe-core-componen.patch
#    0011-dtrace-profile-and-tick-providers-built-on-cyclics.patch
#    0012-dtrace-USDT-and-pid-provider-core-and-x86-components.patch
#    0013-dtrace-USDT-and-pid-providers.patch
#    0014-dtrace-function-boundary-tracing-FBT-core-and-x86-co.patch
#    0015-dtrace-fbt-provider-modular-components.patch
#    0016-dtrace-arm-arm64-port.patch
#    0017-dtrace-add-SDT-probes.patch
#    0018-dtrace-add-sample-script-for-building-DTrace-on-Fedo.patch
    0019-locking-publicize-mutex_owner-and-mutex_owned-again.patch
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
	# Ensure we have enough disk space to compile
	if use binary ; then
		CHECKREQS_DISK_BUILD="5G"
		check-reqs_pkg_setup
	fi
}

pkg_setup() {
	export REAL_ARCH="$ARCH"
	unset ARCH; unset LDFLAGS #will interfere with Makefile if set
}

src_unpack() {

    # unpack the kernel sources to ${WORKDIR}
    unpack ${KERNEL_ARCHIVE} || die "failed to unpack kernel sources"

    # unpack the various kconfig files into a single file
    cat "${DISTDIR}"/debian-kconfig-* >> "${WORKDIR}"/debian-kconfig-${PV} || die "failed to unpack kconfig"
}

src_prepare() {

	### PATCHES ###

    # apply gentoo patches
    einfo "Applying Gentoo Linux patches ..."
    for my_patch in ${GENTOO_PATCHES[*]} ; do
        eapply "${GENTOO_PATCHES_DIR}/${my_patch}" || die "failed to apply Gentoo Linux patches"
    done

    # apply hardening patches
    einfo "Applying hardening patches ..."
    for my_patch in ${HARDENED_PATCHES[*]} ; do
        eapply "${HARDENED_PATCHES_DIR}/${my_patch}" || die "failed to apply hardened patches"
    done

    if use dtrace ; then
        # apply DTrace patches
        einfo "Applying DTrace patches ..."
        for my_patch in ${DTRACE_PATCHES[*]} ; do
            eapply "${DTRACE_PATCHES_DIR}/${my_patch}" || die "failed to apply DTrace patches"
        done
    fi

    if ! use hardened; then
        eapply "${FILESDIR}"/${KERNEL_VERSION}/gentoo-patches/1510_fs-enable-link-security-restrictions-by-default.patch
    fi

    # append EXTRAVERSION to the kernel sources Makefile
    sed -i -e "s:^\(EXTRAVERSION =\).*:\1 ${KERNEL_EXTRAVERSION}:" Makefile || die "failed to append EXTRAVERSION to kernel Makefile"

    # todo: look at this, haven't seen it used in many cases.
    sed -i -e 's:#export\tINSTALL_PATH:export\tINSTALL_PATH:' Makefile || die "failed to fix-up INSTALL_PATH in kernel Makefile"

    # copy the kconfig file into the kernel sources tree
    cp "${WORKDIR}"/debian-kconfig-${PV} "${S}"/.config

    ### TWEAK CONFIG ###

    # Do not configure Debian devs certificates
    echo 'CONFIG_SYSTEM_TRUSTED_KEYS=""' >> .config

    # enable IKCONFIG so that /proc/config.gz can be used for various checks
    # TODO: Maybe not a good idea for USE=hardened, look into this...
    echo "CONFIG_IKCONFIG=y" >> .config
    echo "CONFIG_IKCONFIG_PROC=y" >> .config

    if use custom-cflags; then
        MARCH="$(python -c "import portage; print(portage.settings[\"CFLAGS\"])" | sed 's/ /\n/g' | grep "march")"
        if [ -n "$MARCH" ]; then
                sed -i -e 's/-mtune=generic/$MARCH/g' arch/x86/Makefile || die "Canna optimize this kernel anymore, captain!"
        fi
    fi

    # only enable debugging symbols etc if USE=debug...
    if use debug; then
        echo "CONFIG_DEBUG_INFO=y" >> .config
    else
        echo "CONFIG_DEBUG_INFO=n" >> .config
    fi

    if use dtrace; then
        echo "CONFIG_DTRACE=y" >> .config
        echo "CONFIG_DT_CORE=m" >> .config
        echo "CONFIG_DT_FASTTRAP=m" >> .config
        echo "CONFIG_DT_PROFILE=m" >> .config
        echo "CONFIG_DT_SDT=m" >> .config
        echo "CONFIG_DT_SDT_PERF=y" >> .config
        echo "CONFIG_DT_FBT=m" >> .config
        echo "CONFIG_DT_SYSTRACE=m" >> .config
        echo "CONFIG_DT_DT_TEST=m" >> .config
        echo "CONFIG_DT_DT_PERF=m" >> .config
        echo "CONFIG_DT_DEBUG=y" >> .config
        echo "CONFIG_DT_DEBUG_MUTEX=n" >> .config
        echo "CONFIG_CTF=y" >> .config
        echo "CONFIG_WAITFD=y" >> .config
	echo "CONFIG_DEBUG_INFO=y" >> .config
	echo "CONFIG_DEBUG_INFO_REDUCED=n" >> .config
	echo "CONFIG_DEBUG_INFO_SPLIT=n" >> .config
	echo "CONFIG_DEBUG_INFO_DWARF4=n" >> .config
	echo "CONFIG_DEBUG_INFO_BTF=n" >> .config
    fi

    # these options should already be set, but are a hard dependency for ec2, so we ensure they are set if USE=ec2
	if use ec2; then
	    echo "CONFIG_BLK_DEV_NVME=y" >> .config
	    echo "CONFIG_XEN_BLKDEV_FRONTEND=m" >> .config
	    echo "CONFIG_XEN_BLKDEV_BACKEND=m" >> .config
	    echo "CONFIG_IXGBEVF=m" >> .config
	fi

	# hardening opts
	# TODO: document these
    if use hardened; then
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
        echo 'CONFIG_KEXEC=n' >> .config
        echo "CONFIG_KEXEC_FILE=n" >> .config
        echo 'CONFIG_KEXEC_SIG=n' >> .config
    fi

    # mcelog is deprecated, but there are still some valid use cases and requirements for it... so stick it behind a USE flag for optional kernel support.
    if use mcelog; then
        echo "CONFIG_X86_MCELOG_LEGACY=y" >> .config
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

    # enable wireguard support within kernel
    if use wireguard; then
        echo 'CONFIG_WIREGUARD=m' >> .config
        # there are some other options, but I need to verify them first, so I'll start with this
    fi

	# get config into good state:
	yes "" | make oldconfig >/dev/null 2>&1 || die
	cp .config "${T}"/.config || die
	make -s mrproper || die "make mrproper failed"

	# Apply any user patches
	eapply_user
}

src_configure() {

	if use binary; then

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

        mkdir -p "${WORKDIR}"/modprep || die
        cp "${T}"/.config "${WORKDIR}"/modprep/ || die
        emake O="${WORKDIR}"/modprep "${MAKEARGS[@]}" olddefconfig || die "kernel configure failed"
        emake O="${WORKDIR}"/modprep "${MAKEARGS[@]}" modules_prepare || die "modules_prepare failed"
        cp -pR "${WORKDIR}"/modprep "${WORKDIR}"/build || die
    fi
}

src_compile() {

    if use binary; then

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
	cp -a "${S}" "${D}"/usr/src/linux-${PV}${KERNEL_EXTRAVERSION} || die "failed to install kernel sources"

	# change to installed kernel sources directory
	cd "${D}"/usr/src/linux-${PV}${KERNEL_EXTRAVERSION}

	# prepare for real-world use and 3rd-party module building:
	make mrproper || die "failed to prepare kernel sources"

	# copy kconfig into place
	cp "${T}"/.config .config || die "failed to copy kconfig from ${TEMPDIR}"

	# if we didn't USE=binary - we're done.
	# The kernel source tree is left in an unconfigured state - you can't compile 3rd-party modules against it yet.
	if use binary; then
        make prepare || die
        make scripts || die

        local targets=( modules_install )

        # ARM / ARM64 requires dtb
        if (use arm || use arm64); then
                targets+=( dtbs_install )
        fi

        emake O="${WORKDIR}"/build "${MAKEARGS[@]}" INSTALL_MOD_PATH="${ED}" INSTALL_PATH="${ED}/boot" "${targets[@]}"
        installkernel "${PV}${KERNEL_EXTRAVERSION}" "${WORKDIR}/build/arch/x86_64/boot/bzImage" "${WORKDIR}/build/System.map" "${EROOT}/boot"

        # module symlink fix-up:
        rm -rf "${D}"/lib/modules/${PV}${KERNEL_EXTRAVERSION}/source || die "failed to remove old kernel source symlink"
        rm -rf "${D}"/lib/modules/${PV}${KERNEL_EXTRAVERSION}/build || die "failed to remove old kernel build symlink"

        # Set-up module symlinks:
        ln -s /usr/src/linux-${PV}${KERNEL_EXTRAVERSION} "${ED}"/lib/modules/${PV}${KERNEL_EXTRAVERSION}/source || die "failed to create kernel source symlink"
        ln -s /usr/src/linux-${PV}${KERNEL_EXTRAVERSION} "${ED}"/lib/modules/${PV}${KERNEL_EXTRAVERSION}/build || die "failed to create kernel build symlink"

        # Fixes FL-14
        cp "${WORKDIR}/build/System.map" "${D}"/usr/src/linux-${PV}${KERNEL_EXTRAVERSION}/ || die "failed to install System.map"
        cp "${WORKDIR}/build/Module.symvers" "${D}"/usr/src/linux-${PV}${KERNEL_EXTRAVERSION}/ || die "failed to install Module.symvers"

        if use sign-modules; then
            for x in $(find "${D}"/lib/modules -iname *.ko); do
                # $certs_dir defined previously in this function.
                ${WORKDIR}/build/scripts/sign-file sha512 $certs_dir/signing_key.pem $certs_dir/signing_key.x509 $x || die
            done
            # install the sign-file executable for future use.
            exeinto /usr/src/linux-${PV}-${KERNEL_EXTRAVERSION}/scripts
            doexe ${WORKDIR}/build/scripts/sign-file
        fi
    fi
}

pkg_postinst() {

	# TODO: Change to SANDBOX_WRITE=".." for Dracut writes
	export SANDBOX_ON=0

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
	    ewarn "/usr/src/linux symlink automatically set to linux-${PV}${KERNEL_EXTRAVERSION}"
	    ewarn ""
		ln -sf "${EROOT}"/usr/src/linux-${PV}${KERNEL_EXTRAVERSION} "${EROOT}"/usr/src/linux
	fi

    # if there's a modules folder for these sources, generate modules.dep and map files
    if [[ -d ${EROOT}/lib/modules/${PV}${KERNEL_EXTRAVERSION} ]]; then
        depmod -a ${PV}${KERNEL_EXTRAVERSION}
    fi

	# NOTE: WIP and not well tested yet.
	#
	# Dracut will build an initramfs when USE=binary.
	#
	# The initramfs will be configurable via USE, i.e.
	# USE=zfs will pass '--zfs' to Dracut
	# USE=-systemd will pass '--omit dracut-systemd systemd systemd-networkd systemd-initrd' to exclude these (Dracut) modules from the initramfs.
	#
	# NOTE 2: this will create a fairly.... minimal, and modular initramfs. It has been tested with things with ZFS and LUKS, and 'works'.
	# Things like network support have not been tested (I am currently unsure how well this works with Gentoo Linux based systems),
	# and may end up requiring network-manager for decent support (this really needs further research).
	if use binary; then
	    einfo ""
        einfo ">>> Dracut: building initramfs"
        dracut \
        --stdlog=1 \
        --force \
        --no-hostonly \
        --add "base dm fs-lib i18n kernel-modules rootfs-block shutdown terminfo udev-rules usrmount" \
        --omit "biosdevname bootchart busybox caps convertfs dash debug dmsquash-live dmsquash-live-ntfs fcoe fcoe-uefi fstab-sys gensplash ifcfg img-lib livenet mksh network network-manager qemu qemu-net rpmversion securityfs ssh-client stratis syslog url-lib" \
        $(usex btrfs "-a btrfs" "-o btrfs") \
        $(usex dmraid "-a dmraid" "-o dmraid") \
        $(usex hardened "-o resume" "-a resume") \
        $(usex iscsi "-a iscsi" "-o iscsi") \
        $(usex lvm "-a lvm" "-o lvm") \
        $(usex lvm "--lvmconf" "--nolvmconf") \
        $(usex luks "-a crypt" "-o crypt") \
        $(usex mdadm "--mdadmconf" "--nomdadmconf") \
        $(usex mdadm "-a mdraid" "-o mdraid") \
        $(usex microcode "--early-microcode" "--no-early-microcode") \
        $(usex multipath "-a multipath" "-o multipath") \
        $(usex nbd "-a nbd" "-o nbd") \
        $(usex nfs "-a nfs" "-o nfs") \
        $(usex plymouth "-a plymouth" "-o plymouth") \
        $(usex selinux "-a selinux" "-o selinux") \
        $(usex systemd "-a systemd -a systemd-initrd -a systemd-networkd" "-o systemd -o systemd-initrd -o systemd-networkd") \
        $(usex zfs "-a zfs" "-o zfs") \
        --kver ${PV}${KERNEL_EXTRAVERSION} \
        --kmoddir ${EROOT}/lib/modules/${PV}${KERNEL_EXTRAVERSION} \
        --fwdir ${EROOT}/lib/firmware \
        --kernel-image ${EROOT}/boot/vmlinuz-${PV}${KERNEL_EXTRAVERSION}
        einfo ""
        einfo ">>> Dracut: Finished building initramfs"
        ewarn ""
        ewarn "WARNING... WARNING... WARNING..."
        ewarn ""
        ewarn "Dracut initramfs has been generated!"
        ewarn ""
        ewarn "Required kernel arguments:"
        ewarn ""
        ewarn "    root=/dev/ROOT"
        ewarn ""
        ewarn "    Where ROOT is the device node for your root partition as the"
        ewarn "    one specified in /etc/fstab"
        ewarn ""
        ewarn "Additional kernel cmdline arguments that *may* be required to boot properly..."
        ewarn ""
        ewarn "If you use hibernation:"
        ewarn ""
        ewarn "    resume=/dev/SWAP"
        ewarn ""
        ewarn "    Where $SWAP is the swap device used by hibernate software of your choice."
        ewarn""
        ewarn "    Please consult "man 7 dracut.kernel" for additional kernel arguments."
	fi

    # warn about the issues with running a hardened kernel
    if use hardened; then
        ewarn ""
        ewarn "WARNING... WARNING... WARNING..."
        ewarn ""
        ewarn "Hardened patches have been applied to the kernel and KCONFIG options have been set."
        ewarn "These KCONFIG options and patches change kernel behavior."
        ewarn "Changes include:"
        ewarn "Increased entropy for Address Space Layout Randomization"
        ewarn "GCC plugins (if using GCC)"
        ewarn "Memory allocation"
        ewarn "... and more"
        ewarn ""
        ewarn "These changes will stop certain programs from functioning"
        ewarn "e.g. VirtualBox, Skype"
        ewarn "Full information available in $DOCUMENTATION"
        ewarn ""
    fi

    # if there are out-of-tree kernel modules detected, warn warn warn
	# TODO: tidy up below
	if use binary && [[ -e "${EROOT}"/var/lib/module-rebuild/moduledb ]]; then
	    ewarn ""
		ewarn "WARNING... WARNING... WARNING..."
		ewarn ""
		ewarn "External kernel modules are not yet automatically built"
		ewarn "by USE=binary - emerge @modules-rebuild to do this"
		ewarn "and regenerate your initramfs if you are using ZFS root filesystem"
		ewarn ""
	fi

	if use binary; then
		if [[ -e /etc/boot.conf ]]; then
			ego boot update
		fi
	fi
}
