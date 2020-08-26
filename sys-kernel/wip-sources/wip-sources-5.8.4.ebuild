# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit check-reqs eutils mount-boot toolchain-funcs

DESCRIPTION="Linux kernel sources"
HOMEPAGE="https://kernel.org"

LICENSE="GPL-2"
KEYWORDS="*"

SLOT=$PF

# Upstream kernel sources
KERNEL_VER="5.8.4"
KERNEL_ARCHIVE="linux-${KERNEL_VER}.tar.xz"
KERNEL_UPSTREAM="https://cdn.kernel.org/pub/linux/kernel/v5.x/"

SRC_URI="
    ${KERNEL_UPSTREAM}${KERNEL_ARCHIVE}
"

# Gentoo Linux kernel patches
GENPATCHES_VER="5.8"
GENPATCHES_REVISION="6"
GENPATCHES_BASE_ARCHIVE="genpatches-${GENPATCHES_VER}-${GENPATCHES_REVISION}.base.tar.xz"
GENPATCHES_EXTRAS_ARCHIVE="genpatches-${GENPATCHES_VER}-${GENPATCHES_REVISION}.extras.tar.xz"
GENPATCHES_EXPERIMENTAL_ARCHIVE="genpatches-${GENPATCHES_VER}-${GENPATCHES_REVISION}.experimental.tar.xz"
GENPATCHES_UPSTREAM="https://dev.gentoo.org/~mpagano/genpatches/tarballs/"

SRC_URI+="
    !vanilla? (
        ${GENPATCHES_UPSTREAM}${GENPATCHES_BASE_ARCHIVE}
        ${GENPATCHES_UPSTREAM}${GENPATCHES_EXTRAS_ARCHIVE}
        experimental? (
            ${GENPATCHES_UPSTREAM}${GENPATCHES_EXPERIMENTAL_ARCHIVE}
        )
    )
"

IUSE="binary btrfs clang custom-cflags dmraid dtrace ec2 experimental firmware hardened iscsi libressl luks lvm mdadm microcode multipath nbd nfs plymouth selinux sign-modules systemd vanilla wireguard zfs"

BDEPEND="
	sys-devel/bc
	virtual/libelf
"

DEPEND="
	binary? ( sys-kernel/dracut )
	btrfs? ( sys-fs/btrfs-progs )
	firmware? (
		sys-kernel/linux-firmware
	)
	luks? ( sys-fs/cryptsetup )
	lvm? ( sys-fs/lvm2 )
	mdadm? ( sys-fs/mdadm )
	plymouth? (
		x11-libs/libdrm[libkms]
		sys-boot/plymouth[libkms,udev]
	)
	sign-modules? (
		|| ( dev-libs/openssl ) ( dev-libs/libressl )
		sys-apps/kmod
	)
	systemd? ( sys-apps/systemd )
	wireguard? ( virtual/wireguard )
	zfs? ( sys-fs/zfs )
"

REQUIRED_USE="
	btrfs? ( binary )
	custom-cflags? ( binary )
	ec2? ( binary )
	libressl? ( binary )
	luks? ( binary )
	lvm? ( binary )
	mdadm? ( binary )
	microcode? ( binary )
	plymouth? ( binary )
	selinux? ( binary )
	sign-modules? ( binary )
	systemd? ( binary )
	wireguard? ( binary )
	zfs? ( binary )
"

get_patch_list() {
	[[ -z "${1}" ]] && die "No patch series file specified"
	local patch_series="${1}"
	while read line ; do
		if [[ "${line:0:1}" != "#" ]] ; then
			echo "${line}"
		fi
	done < "${patch_series}"
}

tweak_config() {
	einfo "Setting $2=$3 in kernel config."
	sed -i -e "/^$2=/d" $1
}

zap_config() {
	einfo "Removing *$2* from kernel config."
	sed -i -e "/$2/d" $1
}

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

    # does what it says on the tin...
    if use hardened && use vanilla; then
        die "vanilla and hardened USE flags are incompatible - Disable one of them."
    fi

	# ensure we have enough disk space to compile
	if use binary ; then
		CHECKREQS_DISK_BUILD="5G"
		check-reqs_pkg_setup
	fi
}

pkg_setup() {
	export REAL_ARCH="$ARCH"
	unset ARCH; unset LDFLAGS #will interfere with Makefile if set
}

src_prepare() {

	debug-print-function ${FUNCNAME} "${@}"

    # apply debian patches
	for debpatch in $( get_patch_list "${WORKDIR}/debian/patches/series" ); do
		eapply -p1 "${WORKDIR}/debian/patches/${debpatch}"
	done

	# do not include debian devs certificates
	rm -rf "${WORKDIR}"/debian/certs

	sed -i -e "s:^\(EXTRAVERSION =\).*:\1 ${MODULE_EXT}:" Makefile || die
	sed	-i -e 's:#export\tINSTALL_PATH:export\tINSTALL_PATH:' Makefile || die

	rm -f .config >/dev/null
	cp -a "${WORKDIR}"/debian "${T}"
	make -s mrproper || die "make mrproper failed"
	#make -s include/linux/version.h || die "make include/linux/version.h failed"
	cd "${S}"
	cp -aR "${WORKDIR}"/debian "${S}"/debian

	## increase bluetooth polling patch
	eapply "${FILESDIR}"/${DEB_PV_BASE}/fix-bluetooth-polling.patch

	# Restore export_kernel_fpu_functions for zfs
	eapply "${FILESDIR}"/${DEB_PV_BASE}/export_kernel_fpu_functions_5_3.patch

	local arch featureset subarch
	featureset="standard"
	if [[ ${REAL_ARCH} == x86 ]]; then
		arch="i386"
		subarch="686-pae"
	elif [[ ${REAL_ARCH} == amd64 ]]; then
		arch="amd64"
		subarch="amd64"
	elif [[ ${REAL_ARCH} == arm64 ]]; then
		arch="arm64"
		subarch="arm64"
	else
	    die "Architecture not handled in ebuild"
	fi

    # Copy 'config-extract' tool to the work directory
	cp "${FILESDIR}"/config-extract . || die

	# ... and make it executable
	chmod +x config-extract || die

	# ... and now extract the kernel config file!
	./config-extract ${arch} ${featureset} ${subarch} || die

    ### TWEAK KERNEL CONFIG ###

    ## FL-3381 Enable IKCONFIG so that /proc/config.gz can be used for various checks
    ## TODO: Maybe not a good idea for USE=hardened, look into this.
    tweak_config .config CONFIG_IKCONFIG y
    tweak_config .config CONFIG_IKCONFIG_PROC y

    ## FL-4424 Enable legacy support for MCELOG
    ## TODO: See if this is still required? if not, can it be shit canned?
    tweak_config .config CONFIG_X86_MCELOG_LEGACY y

    ## FL-823 Build XFS into kernel
    ## TODO: can most likely be shit canned as no longer using genkernel, + Dracut includes all kernel moduels in initrd.
    tweak_config .config CONFIG_XFS_FS y
    tweak_config .config CONFIG_LIBCRC32C y

    ## Do not configure Debian devs certificates
    tweak_config .config CONFIG_SYSTEM_TRUSTED_KEYS

	set_no_config .config CONFIG_DEBUG
    if use custom-cflags; then
            MARCH="$(python -c "import portage; print(portage.settings[\"CFLAGS\"])" | sed 's/ /\n/g' | grep "march")"
            if [ -n "$MARCH" ]; then
                    sed -i -e 's/-mtune=generic/$MARCH/g' arch/x86/Makefile || die "Canna optimize this kernel anymore, captain!"
            fi
    fi
	if use ec2; then
		tweak_config .config CONFIG_BLK_DEV_NVME y
		tweak_config .config CONFIG_XEN_BLKDEV_FRONTEND y
		tweak_config .config CONFIG_XEN_BLKDEV_BACKEND y
		tweak_config .config CONFIG_IXGBEVF y
	fi

	# hardening opts
    if use hardened; then
        tweak_config .config CONFIG_AUDIT y
        tweak_config .config CONFIG_EXPERT y
        tweak_config .config CONFIG_SLUB_DEBUG y
        tweak_config .config CONFIG_SLAB_MERGE_DEFAULT n
        tweak_config .config CONFIG_SLAB_FREELIST_RANDOM y
        tweak_config .config CONFIG_SLAB_FREELIST_HARDENED y
        tweak_config .config CONFIG_SLAB_CANARY y
        tweak_config .config CONFIG_SHUFFLE_PAGE_ALLOCATOR y
        tweak_config .config CONFIG_RANDOMIZE_BASE y
        tweak_config .config CONFIG_RANDOMIZE_MEMORY y
        tweak_config .config CONFIG_HIBERNATION n
        tweak_config .config CONFIG_HARDENED_USERCOPY y
        tweak_config .config CONFIG_HARDENED_USERCOPY_FALLBACK n
        tweak_config .config CONFIG_FORTIFY_SOURCE y
        tweak_config .config CONFIG_STACKPROTECTOR y
        tweak_config .config CONFIG_STACKPROTECTOR_STRONG y
        tweak_config .config CONFIG_ARCH_MMAP_RND_BITS 32
        tweak_config .config CONFIG_ARCH_MMAP_RND_COMPAT_BITS 16
        tweak_config .config CONFIG_INIT_ON_FREE_DEFAULT_ON y
        tweak_config .config CONFIG_INIT_ON_ALLOC_DEFAULT_ON y
        tweak_config .config CONFIG_SLAB_SANITIZE_VERIFY y
        tweak_config .config CONFIG_PAGE_SANITIZE_VERIFY y

        # gcc plugins
        ! if use clang; then
            tweak_config .config CONFIG_GCC_PLUGINS y
            tweak_config .config CONFIG_GCC_PLUGIN_LATENT_ENTROPY y
            tweak_config .config CONFIG_GCC_PLUGIN_STRUCTLEAK y
            tweak_config .config CONFIG_GCC_PLUGIN_STRUCTLEAK_BYREF_ALL y
            tweak_config .config CONFIG_GCC_PLUGIN_RANDSTRUCT y
            tweak_config .config CONFIG_GCC_PLUGIN_RANDSTRUCT_PERFORMANCE n
            tweak_config .config CONFIG_GCC_PLUGIN_STACKLEAK y
            tweak_config .config CONFIG_STACKLEAK_TRACK_MIN_SIZE 100
            tweak_config .config CONFIG_STACKLEAK_METRICS n
            tweak_config .config CONFIG_STACKLEAK_RUNTIME_DISABLE n
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
		zap_config .config CONFIG_MODULE_SIG
		# now add our settings:
		tweak_config .config CONFIG_MODULE_SIG y
		tweak_config .config CONFIG_MODULE_SIG_FORCE n
		tweak_config .config CONFIG_MODULE_SIG_ALL n
		# LibreSSL currently (2.9.0) does not have CMS support, so is limited to SHA1.
		# https://bugs.gentoo.org/706086
		# https://bugzilla.kernel.org/show_bug.cgi?id=202159
		if use libressl; then
			tweak_config .config CONFIG_MODULE_SIG_HASH \"sha1\"
		else
			tweak_config .config CONFIG_MODULE_SIG_HASH \"sha512\"
		fi
		tweak_config .config CONFIG_MODULE_SIG_KEY  \"${certs_dir}/signing_key.pem\"
		tweak_config .config CONFIG_SYSTEM_TRUSTED_KEYRING y
		tweak_config .config CONFIG_SYSTEM_EXTRA_CERTIFICATE y
		tweak_config .config CONFIG_SYSTEM_EXTRA_CERTIFICATE_SIZE 4096
		# See above comment re: LibreSSL
		if use libressl; then
			echo "CONFIG_MODULE_SIG_SHA1=y" >> .config
		else
			echo "CONFIG_MODULE_SIG_SHA512=y" >> .config
		fi
		ewarn "This kernel will ALLOW non-signed modules to be loaded with a WARNING."
		ewarn "To enable strict enforcement, YOU MUST add module.sig_enforce=1 as a kernel boot"
		ewarn "parameter (to params in /etc/boot.conf, and re-run boot-update.)"
		echo
	fi
    if use wireguard; then
        tweak_config .config CONFIG_NET y
		tweak_config .config CONFIG_INET y
		tweak_config .config CONFIG_INET_UDP_TUNNEL y
		tweak_config .config CONFIG_NF_CONNTRACK y
		tweak_config .config CONFIG_NETFILTER_XT_MATCH_HASHLIMIT y
		tweak_config .config CONFIG_IP6_NF_IPTABLES y
		tweak_config .config CONFIG_CRYPTO_BLKCIPHER y
		tweak_config .config CONFIG_PADATA y
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

        debug-print-function ${FUNCNAME} "${@}"

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
        debug-print-function ${FUNCNAME} "${@}"

        emake O="${WORKDIR}"/build "${MAKEARGS[@]}" all || "kernel build failed"
    fi
}

src_install() {

	debug-print-function ${FUNCNAME} "${@}"

    # TODO: Change to SANDBOX_WRITE=".." for installkernel writes
	# Disable sandbox
	export SANDBOX_ON=0

	# copy sources into place:
	dodir /usr/src
	cp -a "${S}" "${D}"/usr/src/linux-${PN}-${PV} || die
	cd "${D}"/usr/src/linux-${PN}-${PV}

	# prepare for real-world use and 3rd-party module building:
	make mrproper || die
	cp "${T}"/.config .config || die
	cp -a "${T}"/debian debian || die

	# if we didn't use genkernel, we're done. The kernel source tree is left in
	# an unconfigured state - you can't compile 3rd-party modules against it yet.
	if use binary; then
        make prepare || die
        make scripts || die

        local targets=( modules_install )

        # ARM / ARM64 requires dtb
        if (use arm || use arm64); then
                targets+=( dtbs_install )
        fi

        emake O="${WORKDIR}"/build "${MAKEARGS[@]}" INSTALL_MOD_PATH="${ED}" INSTALL_PATH="${ED}/boot" "${targets[@]}"
        installkernel "${PN}-${PV}" "${WORKDIR}/build/arch/x86_64/boot/bzImage" "${WORKDIR}/build/System.map" "${EROOT}/boot"

        # module symlink fix-up:
        rm -f "${D}"/lib/modules/${PV}-${PN}/source || die
        rm -f "${D}"/lib/modules/${PV}-${PN}/build || die

        # Set-up module symlinks:
        ln -s /usr/src/linux-${PN}-${PV} "${D}"/lib/modules/${PV}-${PN}/source || die "failed to install source symlink"
        ln -s /usr/src/linux-${PN}-${PV} "${D}"/lib/modules/${PV}-${PN}/build || die "failed to install build symlink"

        # Fixes FL-14
        cp "${WORKDIR}/build/System.map" "${D}"/usr/src/linux-${PN}-${PV}/ || die "failed to install System.map"
        cp "${WORKDIR}/build/Module.symvers" "${D}"/usr/src/linux-${PN}-${PV}/ || die "failed to install Module.symvers"

        if use sign-modules; then
            for x in $(find "${D}"/lib/modules -iname *.ko); do
                # $certs_dir defined previously in this function.
                ${WORKDIR}/build/scripts/sign-file sha512 $certs_dir/signing_key.pem $certs_dir/signing_key.x509 $x || die
            done
            # install the sign-file executable for future use.
            exeinto /usr/src/linux-${PN}-${PV}/scripts
            doexe ${WORKDIR}/build/scripts/sign-file
        fi
    fi
}

pkg_postinst() {

	# TODO: Change to SANDBOX_WRITE=".." for Dracut writes
	export SANDBOX_ON=0

	if use binary && [[ -h "${ROOT}"/usr/src/linux ]]; then
		rm "${ROOT}"usr/src/linux
	fi

	if use binary && [[ ! -e "${ROOT}"/usr/src/linux ]]; then
	    ewarn "WARNING... WARNING... WARNING"
	    ewarn ""
	    ewarn "/usr/src/linux symlink automatically set to ${PN}-${PV}"
	    ewarn ""
		ln -sf "${ROOT}"/usr/src/linux-${PN}-${PV} "${ROOT}"/usr/src/linux
	fi

	if [ -e ${ROOT}lib/modules ]; then
		depmod -a ${PV}-${PN}
	fi

	# NOTE: WIP and not well tested yet.
	#
	# Dracut will build an initramfs when USE=binary.
	# The initramfs will be configurable via USE, i.e.
	# USE=zfs will pass '--zfs' to Dracut and USE=-systemd
	# will pass '--omit dracut-systemd systemd systemd-networkd systemd-initrd'
	# to exclude these (Dracut) modules from the initramfs.
	if use binary; then
        einfo ">>> Dracut: building initramfs"
        dracut \
        --stdlog=1 \
        --force \
        --no-hostonly \
        --add "base dm fs-lib i18n kernel-modules network rootfs-block shutdown terminfo udev-rules usrmount" \
        --omit "biosdevname bootchart busybox caps convertfs dash debug dmsquash-live dmsquash-live-ntfs fcoe fcoe-uefi fstab-sys gensplash ifcfg img-lib livenet mksh network-manager qemu qemu-net rpmversion securityfs ssh-client stratis syslog url-lib" \
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
        $(usex systemd "-a systemd systemd-initrd systemd-networkd" "-o systemd systemd-initrd systemd-networkd") \
        $(usex zfs "-a zfs" "-o zfs") \
        --kver "${PV}-${PN}" \
        --kmoddir "${ROOT}"lib/modules/${PV}-${PN} \
        --fwdir "${ROOT}"lib/firmware \
        --kernel-image "${ROOT}"boot/kernel-${PV}-${PN}
        einfo ">>> Dracut: Finished building initramfs"
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

    if use hardened; then
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

    if use wireguard && [[ ${PV} < "5.6.0" ]]; then
        ewarn "WARNING... WARNING... WARNING..."
        ewarn ""
        ewarn "WireGuard with Linux ${PV} is supported as an external kernel module"
        ewarn "You are required to add WireGuard to /etc/conf.d/modules and"
        ewarn "add the 'modules' service to the boot runlevel."
        ewarn ""
        ewarn "e.g rc-update add modules boot"
        ewarn ""
    fi

	# TODO: tidy up below
	if use binary && [[ -e "${ROOT}"var/lib/module-rebuild/moduledb ]]; then
		ewarn "WARNING... WARNING... WARNING..."
		ewarn ""
		ewarn "External kernel modules are not yet automatically built"
		ewarn "by USE=binary - emerge @modules-rebuild to do this"
		ewarn "and regenerate your initramfs if you are using ZFS root filesystem"
		ewarn ""
	fi

	if use binary; then
		if [ -e /etc/boot.conf ]; then
			ego boot update
		fi
	fi
}
