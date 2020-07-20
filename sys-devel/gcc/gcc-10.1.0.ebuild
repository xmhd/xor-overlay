# Distributed under the terms of the GNU General Public License v2

# See README.txt for usage notes.

EAPI=7

inherit flag-o-matic multilib-build eutils pax-utils toolchain-enable git-r3

DESCRIPTION="The GNU Compiler Collection"
HOMEPAGE="https://gcc.gnu.org/"

LICENSE="GPL-3+ LGPL-3+ || ( GPL-3+ libgcc libstdc++ gcc-runtime-library-exception-3.1 ) FDL-1.3+"
KEYWORDS="*"

SLOT="${PV}"

RESTRICT="strip"
FEATURES=${FEATURES/multilib-strict/}

GCC_MAJOR="${PV%%.*}"

IUSE="ada +cxx d go +fortran objc objc++ objc-gc " # Languages
IUSE="$IUSE debug test" # Run tests
IUSE="$IUSE doc nls vanilla hardened +multilib multiarch" # docs/i18n/system flags
IUSE="$IUSE openmp altivec graphite lto pch generic_host" # Optimizations/features flags
IUSE="$IUSE +bootstrap pgo" # Bootstrap flags
IUSE="$IUSE libssp +ssp" # Base hardening flags
IUSE="$IUSE +fortify +link_now +pie vtv" # Extra hardening flags
IUSE="$IUSE +stack_clash_protection" # Stack clash protector added in gcc-8
IUSE="$IUSE sanitize dev_extra_warnings" # Dev flags
IUSE="$IUSE systemtap valgrind zstd" # TODO: sort these flags
IUSE="$IUSE checking_release checking_all"

# Version of archive before patches.
GCC_ARCHIVE_VER="10.1.0"
# GCC release archive
GCC_A="gcc-${GCC_ARCHIVE_VER}.tar.xz"
SRC_URI="ftp://gcc.gnu.org/pub/gcc/releases/gcc-${GCC_ARCHIVE_VER}/${GCC_A}"

GENTOO_PATCHES_DIR="${FILESDIR}/gentoo-patches/${GCC_ARCHIVE_VER}/gentoo"

# We disable a few of these as we set our own 'extra options' for hardening.
# e.g. SSP, PIE, link_now, stack_clash_protection and so on.
GENTOO_PATCHES=(
        #01_all_default-fortify-source.patch
        #02_all_default-warn-format-security.patch
        #03_all_default-warn-trampolines.patch
        04_all_nossp-on-nostdlib.patch
        05_all_alpha-mieee-default.patch
        06_all_ia64_note.GNU-stack.patch
        07_all_i386_libgcc_note.GNU-stack.patch
        08_all_libiberty-asprintf.patch
        09_all_libiberty-pic.patch
        10_all_nopie-all-flags.patch
        11_all_sh-drop-sysroot-suffix.patch
        12_all_ia64-TEXTREL.patch
        13_all_disable-systemtap-switch.patch
        14_all_m68k-textrel-on-libgcc.patch
        15_all_respect-build-cxxflags.patch
        16_all_libgfortran-Werror.patch
        17_all_libgomp-Werror.patch
        18_all_libitm-Werror.patch
        19_all_libatomic-Werror.patch
        20_all_libbacktrace-Werror.patch
        21_all_libsanitizer-Werror.patch
        22_all_libstdcxx-no-vtv.patch
        23_all_disable-riscv32-ABIs.patch
        24_all_default_ssp-buffer-size.patch
        25_all_hppa-faster-synth_mult.patch
        26_all_libcpp-ar.patch
#   	27_all_EXTRA_OPTIONS-z-now.patch
#   	28_all_EXTRA_OPTIONS-fstack-clash-protection.patch
        29_all_fix-float-hang-PR95118.patch
        30_all_lto-intl-workaround-PR95194.patch
        31_all_ctor-range-PR95241.patch
        32_all_plugin-objdump.patch
        33_all_avx512-scalar-PR95528.patch
        34_all_cet-cross-x86.patch
        35_all_ICE-array-subscript-PR95508.patch
        36_all_fno-delayed-branch.patch
)

# Ada Support:
GNAT32="gnat-gpl-2014-x86-linux-bin.tar.gz"
GNAT64="gnat-gpl-2017-x86_64-linux-bin.tar.gz"
SRC_URI="
        $SRC_URI
        ada? (
                amd64? ( mirror://funtoo/gcc/${GNAT64} )
                x86? ( mirror://funtoo/gcc/${GNAT32} )
        )
"

BDEPEND="
    sys-devel/binutils
    >=sys-devel/bison-1.875
    >=sys-devel/flex-2.5.4
    elibc_glibc? ( >=sys-libs/glibc-2.8 )
    elibc_musl? ( sys-libs/musl )
    nls? ( sys-devel/gettext[${MULTILIB_USEDEP}] )
	test? (
	        >=dev-util/dejagnu-1.4.4
	        >=sys-devel/autogen-5.5.4
    )
    valgrind? ( dev-util/valgrind )
"

RDEPEND="
	objc-gc? ( >=dev-libs/boehm-gc-7.6[${MULTILIB_USEDEP}] )
	nls? ( sys-devel/gettext[${MULTILIB_USEDEP}] )
	>=dev-libs/gmp-4.3.2:0=
	graphite? ( >=dev-libs/isl-0.14:0= )
	virtual/libiconv[${MULTILIB_USEDEP}]
	>=dev-libs/mpfr-2.4.2:0=
	>=dev-libs/mpc-0.8.1:0=
	systemtap? ( dev-util/systemtap )
	sys-libs/zlib[${MULTILIB_USEDEP}]
	zstd? ( app-arch/zstd )
"

DEPEND="
    ${RDEPEND}
"

PDEPEND="
    >=sys-devel/gcc-config-1.5
    >=sys-devel/libtool-2.4.3
"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.8 )"
fi

tc-is-cross-compiler() {
	[[ ${CBUILD:-${CHOST}} != ${CHOST} ]]
}

is_crosscompile() {
	[[ ${CHOST} != ${CTARGET} ]]
}

is_native_compile() {
	[[ ${CHOST} == ${CTARGET} ]]
}

pkg_setup() {

    ### INFO ###

    # Set up procedure is as follows:
    #
    # 1) Unset GCC_SPECS and LANGUAGES.
    # 2) Set GCC_BRANCH_VER and GCC_CONFIG_VER.
    # 3) Capture / Filter / Downgrade FLAGS and ARCH where applicable.
    # 4) Set globals for TARGET_ABI, TARGET_DEFAULT_ABI and TARGET_MULTILIB_ABIS.
    # 5) Set and export STAGE1_CFLAGS and BOOT_CFLAGS.
    # 6) Configure BUILD_CONFIG and export.
    # 7) Configure GCC_TARGET and export.

    # we don't want to use the installed compiler's specs to build gcc!
	unset GCC_SPECS
	# Gentoo Linux bug #265283
	unset LANGUAGES

	GCC_BRANCH_VER=${SLOT}
	GCC_CONFIG_VER=${PV}

    # Capture -march, -mcpu, -mtune and -mfpu options to do some initial configuration and optionally pass to build later.
    MARCH="${MARCH:-$(printf -- "${CFLAGS}" | sed -rne 's/.*-march="?([-_[:alnum:]]+).*/\1/p')}"
    MCPU="${MCPU:-$(printf -- "${CFLAGS}" | sed -rne 's/.*-mcpu="?([-_[:alnum:]]+).*/\1/p')}"
    MTUNE="${MTUNE:-$(printf -- "${CFLAGS}" | sed -rne 's/.*-mtune="?([-_[:alnum:]]+).*/\1/p')}"
    MFPU="${MFPU:-$(printf -- "${CFLAGS}" | sed -rne 's/.*-mfpu="?([-_[:alnum:]]+).*/\1/p')}"

    # Print captured flags.
    einfo "Got CFLAGS: ${CFLAGS}"
    einfo "MARCH: ${MARCH}"
    einfo "MCPU ${MCPU}"
    einfo "MTUNE: ${MTUNE}"
    einfo "MFPU: ${MFPU}"

    # DOWNGRADE ARCH FLAGS?

    # FILTER FLAGS?

	# Don't pass cflags/ldflags through. -- remove once filter flags implemented.
	unset CFLAGS
	unset CXXFLAGS
	unset CPPFLAGS
	unset LDFLAGS

    # Export default CTARGET.
    # If CATEGORY == cross-*, export new CTARGET.
	[[ ${CATEGORY} == cross-* ]] && CTARGET=${CATEGORY/cross-}
	export CTARGET=${CTARGET:-${CHOST}}
    if [[ ${CTARGET} = ${CHOST} ]] ; then
        if [[ ${CATEGORY} == cross-* ]] ; then
            export CTARGET=${CATEGORY#cross-}
        fi
    fi

    # Set ABI's
    : ${TARGET_ABI:=${ABI}}
    : ${TARGET_MULTILIB_ABIS:=${MULTILIB_ABIS}}
    : ${TARGET_DEFAULT_ABI:=${DEFAULT_ABI}}

    # Set PATH for PREFIX, LIB, INCLUDE, BIN, DATA and STDCXX_INC.
    export PREFIX=/usr
	LIBPATH=${PREFIX}/lib/gcc/${CTARGET}/${GCC_CONFIG_VER}
	INCLUDEPATH=${LIBPATH}/include}

	if is_crosscompile; then
	    # cross
		BINPATH=${PREFIX}/${CHOST}/${CTARGET}/gcc-bin/${GCC_CONFIG_VER}
		HOSTLIBPATH=${PREFIX}/${CHOST}/${CTARGET}/lib/${GCC_CONFIG_VER}
	else
	    # native
		BINPATH=${PREFIX}/${CTARGET}/gcc-bin/${GCC_CONFIG_VER}
	fi

	DATAPATH=${PREFIX}/share/gcc-data/${CTARGET}/${GCC_CONFIG_VER}
	STDCXX_INCDIR=${LIBPATH}/include/g++-v${GCC_BRANCH_VER}

    # Set STAGE1_CFLAGS and BOOT_CFLAGS below...
    # NOTE: -O0 and -O1 break things, so just don't do it :-)

	# Flags to be used to build stage one compiler.
	STAGE1_CFLAGS="${STAGE1_CFLAGS:--O2 -pipe}"

	# Flags to be used for stages two and three.
	# TODO: allow custom optimisation levels -O3 and -Os
	BOOT_CFLAGS="${BOOT_CFLAGS:--O2 -pipe}"
	BOOT_CFLAGS=${BOOT_CFLAGS:-"$(get_abi_CFLAGS ${TARGET_DEFAULT_ABI}) ${CFLAGS}"}

	# The following blocks of code will configure BUILD_CONFIG and GCC_TARGET.
    #
    # This ebuild will perform 'lean' bootstraps by default, and 'regular' bootstraps when USE=debug.
    #
    # 'Lean' and 'regular' bootstraps have the same build sequence, except the object files from stage one & stage two
    # of the three stage bootstrap process are deleted as soon as they are no longer required.
    #
    # Further additions are made to BUILD_CONFIG and GCC_TARGET for profiled or lto bootstraps.
    #
    # TODO: not entirely happy with this - there are additional BUILD_CONFIG options that can and should be added,
    # e.g. bootstrap-debug, bootstrap-cet.
    #
    # TODO: not sure if this works with cross compile? investigate?
	if use lto && use bootstrap; then
	    BUILD_CONFIG="${BUILD_CONFIG:+${BUILD_CONFIG} }bootstrap-lto-lean"
	fi

    # BUILD_CONFIG finished - export.
	export BUILD_CONFIG

    # Now for GCC_TARGET...

    # only perform a three stage and any additional bootstraps if native...
    # three stage bootstrapping doesnt quite work when you cant run the resulting binaries natively!
	if ! is_crosscompile && ! tc-is-cross-compiler && use bootstrap; then
	    if use pgo; then
	        GCC_TARGET="profiledbootstrap-lean"
	    else
	        GCC_TARGET="bootstrap-lean"
	    fi
	else
	    GCC_TARGET="all"
	fi

    # GCC_TARGET finished - export.
	export GCC_TARGET

	# Setup TARGET_LIBC...
	case ${CTARGET} in
		*-linux)
		    TARGET_LIBC=no-idea;;
		*-dietlibc)
		    TARGET_LIBC=dietlibc;;
		*-elf|*-eabi)
		    TARGET_LIBC=newlib;;
		*-freebsd*)
		    TARGET_LIBC=freebsd-lib;;
		*-gnu*)
		    TARGET_LIBC=glibc;;
		*-klibc)
		    TARGET_LIBC=klibc;;
		*-musl*)
		    TARGET_LIBC=musl;;
		*-uclibc*)
		    TARGET_LIBC=uclibc;;
		avr*)
		    TARGET_LIBC=avr-libc;;
	esac

	# TARGET_LIBC finished - export.
	export TARGET_LIBC

    # Todo
	use doc || export MAKEINFO="/dev/null"
}

src_unpack() {
	unpack $GCC_A

	# GNAT ada support
	if use ada ; then
		if use amd64; then
			unpack $GNAT64 || die "ada setup failed"
		elif use x86; then
			unpack $GNAT32 || die "ada setup failed"
		else
			die "GNAT ada setup failed, only x86 and amd64 currently supported by this ebuild. Patches welcome!"
		fi
	fi
}

eapply_gentoo() {
	eapply "${GENTOO_PATCHES_DIR}/${1}"
}

src_prepare() {

    # Export GCC branding
    # TODO: implement alpha, beta and git brandings possibly?
    if ! use hardened && ! use vanilla; then
        export GCC_BRANDING="Funtoo Linux {$PV}"
    elif use hardened; then
        export GCC_BRANDING="Funtoo Linux Hardened ${PV}"
    fi

    # Initial check
    if use vanilla && use hardened; then
        die "vanilla and hardened USE flags are incompatible - Disable one of them."
    fi

	# For some reason, when upgrading gcc, the gcc Makefile will install stuff
	# like crtbegin.o into a subdirectory based on the name of the currently-installed
	# gcc version, rather than *our* gcc version. Manually fix this:

	sed -i -e "s/^version :=.*/version := ${GCC_CONFIG_VER}/" ${S}/libgcc/Makefile.in || die

    # Only modify sources if USE="-vanilla"
	if ! use vanilla; then

        # Gentoo Linux patches
		if [ -n "$GENTOO_PATCHES_VER" ]; then
			einfo "Applying Gentoo patches ..."
			for my_patch in ${GENTOO_PATCHES[*]} ; do
				eapply_gentoo "${my_patch}"
			done
		fi

		# We use --enable-version-specific-libs with ./configure. This
		# option is designed to place all our libraries into a sub-directory
		# rather than /usr/lib*.  However, this option, even through 4.8.0,
		# does not work 100% correctly without a small fix for
		# libgcc_s.so. See: http://gcc.gnu.org/bugzilla/show_bug.cgi?id=32415.
		# So, we apply a small patch to get this working:

		eapply "${FILESDIR}/gcc-4.6.4-fix-libgcc-s-path-with-vsrl.patch" || die "patch fail"

        # === HARDENING ===
        # TODO: write a blurb
        local gcc_hard_flags=""

        if use dev_extra_warnings ; then
			eapply_gentoo "$(set +f ; cd "${GENTOO_PATCHES_DIR}" && echo ??_all_default-warn-format-security.patch )"
			eapply_gentoo "$(set +f ; cd "${GENTOO_PATCHES_DIR}" && echo ??_all_default-warn-trampolines.patch )"
			if use test ; then
				ewarn "USE=dev_extra_warnings enables warnings by default which are known to break gcc's tests!"
			fi
			einfo "Additional warnings enabled by default, this may break some tests and compilations with -Werror."
		fi

        # -fstack-protector is initially set =-1 in GCC.
        # =0 TODO
        # =1 TODO
        # =2 -all
        # =3 -strong
        # This ebuild defaults to -strong, and if USE=hardened then set it to -strong
        if use ssp && use hardened; then
            gcc_hard_flags+=( -DDEFAULT_FLAG_SSP=2 )
        fi

        # Enable FORTIFY_SOURCE by default
        if use fortify; then
            eapply_gentoo "$(set +f ; cd "${GENTOO_PATCHES_DIR}" && echo ??_all_default-fortify-source.patch )"
        fi

        # Enable LINK_NOW by default
        if use link_now; then
            eapply_gentoo "$(set +f ; cd "${GENTOO_PATCHES_DIR}" && echo ??_all_EXTRA_OPTIONS-z-now.patch )"
            gcc_hard_flags+=" -DEXTRA_OPTIONS "
        fi

        # Enable Stack Clash Protection by default
        if use stack_clash_protection; then
            eapply_gentoo "$(set +f ; cd "${GENTOO_PATCHES_DIR}" && echo ??_all_EXTRA_OPTIONS-fstack-clash-protection.patch )"
            gcc_hard_flags+=" -DEXTRA_OPTIONS "
        fi

	    # GCC stores it's CFLAGS in the Makefile - here we make those CFLAGS == ${gcc_hard_flags} so that they are applied in the build process.
        sed -e '/^ALL_CFLAGS/iHARD_CFLAGS = '  -e 's|^ALL_CFLAGS = |ALL_CFLAGS = $(HARD_CFLAGS) |' -i "${S}"/gcc/Makefile.in
        sed -e '/^ALL_CXXFLAGS/iHARD_CFLAGS = '  -e 's|^ALL_CXXFLAGS = |ALL_CXXFLAGS = $(HARD_CFLAGS) |' -i "${S}"/gcc/Makefile.in

        # write HARD_CFLAGS back to the gcc Makefile.
        sed -i -e "/^HARD_CFLAGS = /s|=|= ${gcc_hard_flags} |" "${S}"/gcc/Makefile.in || die
	fi

	# === OSDIRNAMES ===

    # Historically most Linux distributions used the following setup:
    #    lib32 - 32bit binaries (x86)
    #    lib64 - 64bit binaries (x86_64)
    #    lib   - "native" binaries (a symlink to lib64)
    # Eventually, they (including mainline gcc) began migrating to the following
    #    lib   - 32bit binaries (x86)
    #    lib64 - 64bit binaries (x86_64)
    #
    # TODO: Migrate to latter form? brainstorm at future date.
    #
    # Unfortunately, due to the former, newer gcc versions will dynamically detect which setup to use.
    # So to keep the autodetect magic from getting things wrong, we forcefully set the multilib directories.
    #
    # TODO: musl uses lib and lib only. Implement?
	if use multilib; then
        # TODO
	    local config
	    # TODO
        local libdirs="../lib64 ../lib32"

	    # this only makes sense for some Linux targets as not all support multilib.
        case ${CTARGET} in
            x86_64*-linux*)
                config="i386" ;;
            powerpc64*-linux*)
                config="rs6000" ;;
            sparc64*-linux*)
                config="sparc" ;;
            s390x*-linux*)
                config="s390" ;;
            *)
                return 0 ;;
        esac
        config+="/t-linux64"

        # Array to store our sed commands.
        local sed_args=()

        # TODO
        sed_args+=( -e 's:$[(]call if_multiarch[^)]*[)]::g' )

        # TODO
        einfo "updating multilib directories to be: ${libdirs}"
        sed_args+=( -e "/^MULTILIB_OSDIRNAMES/s:=.*:= ${libdirs}:" )

        # TODO
        sed -i "${sed_args[@]}" "${S}"/gcc/config/${config} || die
	fi

    # === PREPARE ADA TOOLCHAIN ===
    if use ada; then

        export GNATBOOT="${S}/gnatboot"

        if [ -f  gcc/ada/libgnat/s-parame.adb ] ; then
            einfo "Patching ada stack handling..."
            grep -q -e '-- Default_Sec_Stack_Size --' gcc/ada/libgnat/s-parame.adb && eapply "${FILESDIR}/Ada-Integer-overflow-in-SS_Allocate.patch"
        fi

        if use amd64; then
            einfo "Preparing gnat64 for ada:"
            make -C ${WORKDIR}/${GNAT64%%.*} ins-all prefix=${S}/gnatboot > /dev/null || die "ada preparation failed"
            find ${S}/gnatboot -name ld -exec mv -v {} {}.old \;
        elif use x86; then
            einfo "Preparing gnat32 for ada:"
            make -C ${WORKDIR}/${GNAT32%%.*} ins-all prefix=${S}/gnatboot > /dev/null || die "ada preparation failed"
            find ${S}/gnatboot -name ld -exec mv -v {} {}.old \;
        else
            die "GNAT ada setup failed, only x86 and amd64 currently supported by this ebuild. Patches welcome!"
        fi

        # Setup additional paths as needed before we start.
        use ada && export PATH="${GNATBOOT}/bin:${PATH}"
    fi

	# Must be called in src_prepare by EAPI6
	eapply_user
}

gcc_conf_lang_opts() {
	# Determine language support:
	local conf_gcc_lang=""
	local GCC_LANG="c,c++"
	if use objc; then
		GCC_LANG+=",objc"
		use objc-gc && conf_gcc_lang+=" --enable-objc-gc"
		use objc++ && GCC_LANG+=",obj-c++"
	fi

	use fortran && GCC_LANG+=",fortran" || conf_gcc_lang+=" --disable-libquadmath"

	use go && GCC_LANG+=",go"

	use ada && GCC_LANG+=",ada" && conf_gcc_lang+=" CC=${GNATBOOT}/bin/gcc CXX=${GNATBOOT}/bin/g++ AR=${GNATBOOT}/bin/gcc-ar AS=as LD=ld NM=${GNATBOOT}/bin/gcc-nm RANLIB=${GNATBOOT}/bin/gcc-ranlib"

	use d && GCC_LANG+=",d"

    if use lto; then
        GCC_LANG+=",lto"
    fi

	conf_gcc_lang+=" --enable-languages=${GCC_LANG} --disable-libgcj"

	printf -- "${conf_gcc_lang}"
}

# ARM
gcc_conf_arm_opts() {
	# Skip the rest if not an arm target
	[[ ${CTARGET} == arm* ]] || return

	local conf_gcc_arm=""
	local arm_arch=${CTARGET%%-*}
	local a
	# Remove trailing endian variations first: eb el be bl b l
	for a in e{b,l} {b,l}e b l ; do
		if [[ ${arm_arch} == *${a} ]] ; then
			arm_arch=${arm_arch%${a}}
			break
		fi
	done

	# Convert armv7{a,r,m} to armv7-{a,r,m}
	[[ ${arm_arch} == armv7? ]] && arm_arch=${arm_arch/7/7-}

	# See if this is a valid --with-arch flag
	if (srcdir=${S}/gcc target=${CTARGET} with_arch=${arm_arch};
		. "${srcdir}"/config.gcc) &>/dev/null
	then
		conf_gcc_arm+=" --with-arch=${arm_arch}"
	fi

	# Enable hardvfp
	local float="hard"
	local default_fpu=""

	case "${CTARGET}" in
		*[-_]softfloat[-_]*) float="soft" ;;
		*[-_]softfp[-_]*) float="softfp" ;;
		armv[56]*) default_fpu="vfpv2" ;;
		armv7ve*) default_fpu="vfpv4-d16" ;;
		armv7*) default_fpu="vfpv3-d16" ;;
		amrv8*) default_fpu="fp-armv8" ;;
	esac
	
	conf_gcc_arm+=" --with-float=$float"
	[ -z "${MFPU}" ] && [ -n "${default_fpu}" ] && conf_gcc_arm+=" --with-fpu=${default_fpu}"

	printf -- "${conf_gcc_arm}"
}

src_configure() {

    # gcc_conf is our array of opts to pass to ./configure
	local confgcc

	# === BRANDING ===

	# Export GCC branding
    # TODO: implement alpha, beta and git brandings possibly? specific bug tracker/JIRA for specific versions?
    if ! use hardened && ! use vanilla; then
        export GCC_BRANDING="Funtoo Linux {$PV}"
		confgcc+=( --with-bugurl=http://bugs.funtoo.org --with-pkgversion="$GCC_BRANDING" )
    elif use hardened; then
        export GCC_BRANDING="Funtoo Linux Hardened ${PV}"
        confgcc+=( --with-bugurl=http://bugs.funtoo.org --with-pkgversion="$GCC_BRANDING" )
    fi

    # === END BRANDING ===

    # === GENERAL / INITIAL CONFIGURATION ===

    # Set up paths
    #--libdir=${LIBPATH}/lib <<< todo: investigate
    confgcc+=(
        --prefix=${PREFIX}
        --bindir=${BINDIR}
        --includedir=${LIBPATH}/include
        --datadir=${DATAPATH}
        --mandir=${DATAPATH}/man
        --infodir=${DATAPATH/info}
        --with-gxx-include-dir=${STDCXX_INCDIR}
        --with-python-dir=${DATAPATH/$PREFIX/}/python
    )

    confgcc+=(
        --enable-obsolete
        --disable-werror
        --enable-secureplt
        --with-system-zlib
        --enable-clocale=gnu
        --disable-libunwind-exceptions
        --enable-version-specific-runtime-libs
    )

    # Default to '--enable-checking=release', except when USE=debug, in which case '--enable-checking=all'.
    #
    # These checks perform internal consistency checks within gcc, but adds error checking of the requested complexity.
    #
    # checking=release performs checks on assert + compiler runtime, and is fairly cheap.
    # checking=all performs all available tests except 'valgrind', and is fairly expensive.
    #
    # See https://gcc.gnu.org/install/configure.html for further information on the checks available within gcc.
    #
    # NOTE: '--enable-stage1-checking' == ''--enable-checking' unless explicitly specified.
    # NOTE2: '--enable-checking=release' is default $upstream unless disabled via '--enable-checking=no'.
    # NOTE3: $upstream doesn't test '--disable-checking', preferring '--enable-checking=no'. SEE: Gentoo Linux #317217
    if use checking_release; then
        confgcc+=( --enable-checking=release )
    elif use checking_all; then
        confgcc+=( --enable-checking=all )
    fi

    # === END GENERAL CONFIGURATION ===

	# === CHOST / CBUILD / CTARGET ===

    # Set the CHOST.
	local confgcc=( --host=${CHOST} )

    # Set the CTARGET if we are cross compiling.
	if is_crosscompile || tc-is-cross-compiler; then
		# Straight from the GCC install doc:
		# "GCC has code to correctly determine the correct value for target for nearly all native systems.
		# Therefore, we highly recommend you not provide a configure target when configuring a native compiler."
		confgcc+=( --target=${CTARGET} )
	fi

	# TODO: set CBUILD etc for if_is_canadian_cross and is_cross_build

	# Pass CBUILD if one exists
	# Note: can be incorporated to the above.
	if [[ -n ${CBUILD} ]]; then
	    confgcc+=( --build=${CBUILD} )
	fi

	# === END CHOST / CBUILD / CTARGET CONFIGURATION ===

	# === CROSS COMPILER ===

	if is_crosscompile; then
		# Enable build warnings by default with cross-compilers when system paths are included (e.g. via -I flags).
		confgcc+=( --enable-poison-system-directories )

        # three stage bootstrapping doesnt quite work when you cant run the resulting binaries natively!
        confgcc+=( --disable-bootstrap )

        # Force disable for is_crosscompile as the configure script can be dumb - Gentoo Linux bug #359855
        confgcc+=( --disable-libgomp )

        # Configure anything required by a particular TARGET_LIBC...

        # Todo
        if [[ ${CTARGET} == dietlibc* ]]; then
            confgcc+=( --disable-libstdcxx-time )
        fi

        # Todo
        if [[ ${CTARGET} == uclibc* ]]; then
		    # Enable shared library support only on targets that support it: Gentoo Linux bug #291870
			if ! echo '#include <features.h>' | \
			   $(tc-getCPP ${CTARGET}) -E -dD - 2>/dev/null | \
			   grep -q __HAVE_SHARED__
			then
				confgcc+=( --disable-shared )
			fi
        fi

        # Todo
        if [[ ${CTARGET} == avr* ]]; then
            confgcc+=( --disable-__cxa_atexit )
        else
            confgcc+=( --enable-__cxa_atexit )
        fi

        # Todo
        if [[ ${CTARGET} == x86_64-*-mingw* ||  ${CTARGET} == *-w64-mingw* ]]; then
            confgcc+=( --disable-threads --enable-shared )
        fi

        # Handle bootstrapping cross-compiler and libc in lock-step
        if ! has_version ${CATEGORY}/${TARGET_LIBC}; then
            # we are building with libc that is not installed:
            confgcc+=( --disable-shared --disable-libatomic --disable-threads --without-headers --disable-libstdcxx )
        elif has_version "${CATEGORY}/${TARGET_LIBC}[headers-only]"; then
            # libc installed, but has USE="crosscompile_opts_headers-only" to only install headers:
            confgcc+=( --disable-shared --disable-libatomic --with-sysroot=${PREFIX}/${CTARGET} --disable-libstdcxx )
        else
            # libc is installed:
            confgcc+=( --with-sysroot=${PREFIX}/${CTARGET} --enable-libstdcxx-time )
        fi

    else
        # native compiler
        # todo place this above when implemented is_native_compile
		confgcc+=( --enable-threads=posix --enable-__cxa_atexit --enable-libstdcxx-time )
		confgcc+=( $(use_enable openmp libgomp) )
		confgcc+=( $(use_enable bootstrap) --enable-shared )
    fi

    # === END CROSS COMPILER ===

    # === LIBC CONFIGURATION ===

    #
 	# __cxa_atexit is "essential for fully standards-compliant handling of destructors", but apparently requires glibc.
 	#
 	# TODO: this can likely be shit canned.
 	# seems all is already set in above is_native_compile configuration.
 	# I don't really care for supporting building this package natively on solaris, freebsd or uclibc.
 	# TODO: think and return.
	case ${CTARGET} in
        *-uclibc*)
            if use nptl; then
                confgcc+=(
                    --disable-__cxa_atexit
                    $(use_enable nptl tls)
                )
            fi
            ;;
        *-elf|*-eabi)
            confgcc+=( --with-newlib )
            ;;
        *-musl*)
            confgcc+=( --enable-__cxa_atexit )
            ;;
        *-gnu*)
            confgcc+=(
                --enable-__cxa_atexit
                --enable-clocale=gnu
            )
            ;;
        *-freebsd*)
            confgcc+=( --enable-__cxa_atexit )
            ;;
        *-solaris*)
            confgcc+=( --enable-__cxa_atexit )
            ;;
	esac

    # === END LIBC CONFIGURATION ===

    # === ARCH CONFIGURATION ===

    # multilib
    if use multilib; then
        confgcc+=( --enable-multilib )
    else
        confgcc+=( --disable-multilib )
    fi

    # TODO: more multilib config here

    # multiarch
    if use multiarch; then
        confgcc+=( --enable-multiarch )
    else
        confgcc+=( --disable-multiarch )
    fi

    # TODO:
    if ! use generic_host; then
        confgcc+=( ${MARCH:+ --with-arch=${MARCH}}${MCPU:+ --with-cpu=${MCPU}}${MTUNE:+ --with-tune=${MTUNE}}${MFPU:+ --with-fpu=${MFPU}} )
    fi

    # TODO: ARM SPECIFIC STUFF GOES HERE HERE
    # TODO: switch statement case $(tc-arch) in ... set --with-abi etc... possibly the above?

	# If the target can do biarch (-m32/-m64), enable it.
	# Overhead should be small, and should simplify building of 64bit kernels in a 32bit userland by not needing kgcc64.
	# Gentoo Linux bug #349405
	case $(tc-arch) in
	    ppc|ppc64)
	        confgcc+=( --enable-targets=all )
	    ;;
	    sparc)
	        confgcc+=( --enable-targets=all )
	        ;;
	    amd64|x86)
	        confgcc+=( --enable-targets=all )
	        ;;
	esac

	# === END ARCH CONFIGURATION ===

    # === FEATURE / LIBRARY CONFIGURATION ===

    # graphite todo
    if use graphite; then
        confgcc+=( --with-isl --disable-isl-version-check )
    else
        confgcc+=( --without-isl )
    fi

    # lto todo
    if use lto; then
        confgcc+=( --enable-lto )
    else
        confgcc+=( --disable-lto )
    fi

    if use nls ; then
		confgcc+=( --enable-nls --without-included-gettext )
	else
		confgcc+=( --disable-nls )
	fi

    # Default building of PIE executables.
    if use pie; then
        confgcc+=( --enable-default-pie )
    else
        confgcc+=( --disable-default-pie )
    fi

    if ! use pch; then
        confgcc+=( --disable-libstdcxx-pch )
    fi

	if use sanitize; then
	    confgcc+=( --enable-libsanitizer )
	else
	    confgcc+=( --disable-libsanitizer )
	fi

	# Default building of SSP executables.
    if use ssp; then
        confgcc+=( --enable-default-ssp )
    else
        confgcc+=( --disable-default-ssp )
    fi

    if use systemtap; then
        confgcc+=( --enable-systemtap )
    else
        confgcc+=( --disable-systemtap )
    fi

    # valgrind toolsuite provides various debugging and profiling tools
    if use valgrind; then
        confgcc+=( --enable-valgrind --enable-valgrind-annotations )
    else
        confgcc+=( --disable-valgrind --disable-valgrind-annotations )
    fi

    if use vtv; then
		confgcc+=( --enable-vtable-verify --enable-libvtv )
    else
		confgcc+=( --disable-vtable-verify --disable-libvtv )
	fi

    # gcc has support for compressing lto bytecode using zstd
    if use zstd; then
        confgcc+=( --with-zstd )
    else
        confgcc+=( --without-zstd )
    fi

    # can this be shit canned? is solaris only, and i have better things to do with my time than support that
    use libssp || export gcc_cv_libc_provides_ssp=yes
    if use libssp; then
        confgcc+=( --enable-libssp )

    fi

    # === END FEATURE / LIBRARY CONFIGURATION ===

    # Pass any local EXTRA_ECONF from /etc/portage/env to ./configure.
    confgcc+=( "$@" ${EXTRA_ECONF} )

    # Pass BUILD_CONFIG to ./configure.
    confgcc+=( --with-build-config=${BUILD_CONFIG} )

	# Create build directory...
	mkdir -p "${WORKDIR}"/build || die "create build directory failed"

	# ... and cd to the newly created build directory.
	cd "${WORKDIR}"/build || die "cd to build directory failed"

    # finally run ./configure!
	../gcc-${PV}/configure $(gcc_conf_lang_opts) $(gcc_conf_arm_opts) $confgcc || die "configure fail"

	is_crosscompile && gcc_conf_cross_post
}

gcc_conf_cross_post() {
	if use arm ; then
		sed -i "s/none-/${CHOST%%-*}-/g" ${WORKDIR}/build/Makefile || die
	fi

}

src_compile() {

    einfo "Building ${PN} (${GCC_MAKE_TARGET})..."

	# Run make against GCC_TARGET, setting some variables as required.
	emake -C "${WORKDIR}"/build \
            LDFLAGS="${LDFLAGS}" \
            STAGE1_CFLAGS="${STAGE1_CFLAGS}" \
            BOOT_CFLAGS="${BOOT_CFLAGS}" \
	        LIBPATH="${LIBPATH}" \
            ${GCC_TARGET} || die "emake failed with ${GCC_TARGET}"

    # Optionally build some docs
	if ! is_crosscompile && use cxx && use doc; then
		emake -C "${WORKDIR}"/build/"${CTARGET}"/libstdc++-v3/doc doc-man-doxygen
	fi
}

src_test() {
	cd "${WORKDIR}/build"
	unset ABI
	local tests_failed=0
	if is_crosscompile || tc-is-cross-compiler; then
		ewarn "Running tests on simulator for cross-compiler not yet supported by this ebuild."
	else
		( ulimit -s 65536 && ${MAKE:-make} ${MAKEOPTS} LIBPATH="${ED%/}/${LIBPATH}" -k check RUNTESTFLAGS="-v -v -v" 2>&1 | tee ${T}/make-check-log ) || tests_failed=1
		"../${S##*/}/contrib/test_summary" 2>&1 | tee "${T}/gcc-test-summary.out"
		[ ${tests_failed} -eq 0 ] || die "make -k check failed"
	fi
}

create_gcc_env_entry() {
	dodir /etc/env.d/gcc
	local gcc_envd_base="/etc/env.d/gcc/${CTARGET}-${GCC_CONFIG_VER}"
	local gcc_envd_file="${D}${gcc_envd_base}"
	if [ -z $1 ]; then
		gcc_specs_file=""
	else
		gcc_envd_file="$gcc_envd_file-$1"
		gcc_specs_file="${LIBPATH}/$1.specs"
	fi

	# set abi stuff here
	# We want to list the default ABI's LIBPATH first so libtool
	# searches that directory first.  This is a temporary
	# workaround for libtool being stupid and using .la's from
	# conflicting ABIs by using the first one in the search path
    local ldpaths mosdirs mdir mosdir abi ldpath
    for abi in $(get_all_abis TARGET) ; do
        mdir=$($(XGCC) $(get_abi_CFLAGS ${abi}) --print-multi-directory)
        ldpath=${LIBPATH}
        [[ ${mdir} != "." ]] && ldpath+="/${mdir}"
        ldpaths="${ldpath}${ldpaths:+:${ldpaths}}"

        mosdir=$($(XGCC) $(get_abi_CFLAGS ${abi}) -print-multi-os-directory)
        mosdirs="${mosdir}${mosdirs:+:${mosdirs}}"
    done

	cat <<-EOF > ${gcc_envd_file}
	GCC_PATH="${BINPATH}"
	LDPATH="${LIBPATH}:${LIBPATH}/32"
	MANPATH="${DATAPATH}/man"
	INFOPATH="${DATAPATH}/info"
	STDCXX_INCDIR="${STDCXX_INCDIR##*/}"
	CTARGET="${CTARGET}"
	GCC_SPECS="${gcc_specs_file}"
	MULTIOSDIRS="${mosdirs}"
	EOF

	if is_crosscompile; then
		echo "CTARGET=\"${CTARGET}\"" >> ${gcc_envd_file}
	fi
}

linkify_compiler_binaries() {
	dodir ${PREFIX}/bin
	cd "${D}"${BINPATH}
	# Ugh: we really need to auto-detect this list.
	#	   It's constantly out of date.

	local binary_languages="cpp gcc g++ c++ gcov"
	local gnat_bins="gnat gnatbind gnatchop gnatclean gnatfind gnatkr gnatlink gnatls gnatmake gnatname gnatprep gnatxref"

	use go && binary_languages="${binary_languages} gccgo"
	use fortran && binary_languages="${binary_languages} gfortran"
	use ada && binary_languages="${binary_languages} ${gnat_bins}"
	use d && binary_languages="${binary_languages} gdc"

	for x in ${binary_languages} ; do
		[[ -f ${x} ]] && mv ${x} ${CTARGET}-${x}

		if [[ -f ${CTARGET}-${x} ]] ; then
			if ! is_crosscompile; then
				ln -sf ${CTARGET}-${x} ${x}
				dosym ${BINPATH}/${CTARGET}-${x} ${PREFIX}/bin/${x}-${GCC_CONFIG_VER}
			fi
			# Create version-ed symlinks
			dosym ${BINPATH}/${CTARGET}-${x} ${PREFIX}/bin/${CTARGET}-${x}-${GCC_CONFIG_VER}
		fi

		if [[ -f ${CTARGET}-${x}-${GCC_CONFIG_VER} ]] ; then
			rm -f ${CTARGET}-${x}-${GCC_CONFIG_VER}
			ln -sf ${CTARGET}-${x} ${CTARGET}-${x}-${GCC_CONFIG_VER}
		fi
	done
}

tasteful_stripping() {
	# Now do the fun stripping stuff
	[[ ! is_crosscompile ]] && \
		env RESTRICT="" CHOST=${CHOST} dostrip "${D}${BINPATH}" ; \
		env RESTRICT="" CHOST=${CTARGET} dostrip "${D}${LIBPATH}"
	# gcc used to install helper binaries in lib/ but then moved to libexec/
	[[ -d ${D}${PREFIX}/libexec/gcc ]] && \
		env RESTRICT="" CHOST=${CHOST} dostrip "${D}${PREFIX}/libexec/gcc/${CTARGET}/${GCC_CONFIG_VER}"
}

doc_cleanups() {
	local cxx_mandir=$(find "${WORKDIR}/build/${CTARGET}/libstdc++-v3" -name man)
	if [[ -d ${cxx_mandir} ]] ; then
		# clean bogus manpages #113902
		find "${cxx_mandir}" -name '*_build_*' -exec rm {} \;
		( set +f ; cp -r "${cxx_mandir}"/man? "${D}/${DATAPATH}"/man/ )
	fi

	# Remove info files if we don't want them.
	if is_crosscompile || ! use doc || has noinfo ${FEATURES} ; then
		rm -r "${D}/${DATAPATH}"/info
	else
		doinfo "${DATAPATH}"
	fi

	# Strip man files too if 'noman' feature is set.
	if is_crosscompile || has noman ${FEATURES} ; then
		rm -r "${D}/${DATAPATH}"/man
	else
		prepman "${DATAPATH}"
	fi
}

cross_toolchain_env_setup() {

	# old xcompile bashrc stuff here
	dosym /etc/localtime /usr/${CTARGET}/etc/localtime
	for file in /usr/lib/gcc/${CTARGET}/${GCC_CONFIG_VER}/libstdc*; do
		dosym "$file" "/usr/${CTARGET}/lib/$(basename $file)"
	done
	mkdir -p /etc/revdep-rebuild
	insinto "/etc/revdep-rebuild"
	string="SEARCH_DIRS_MASK=\"/usr/${CTARGET} "
	for dir in /usr/lib/gcc/${CTARGET}/*; do
		string+="$dir "
	done
	for dir in /usr/lib64/gcc/${CTARGET}/*; do
		string+="$dir "
	done
	string="${string%?}"
	string+='"' 
	if [[ -e /etc/revdep-rebuild/05cross-${CTARGET} ]] ; then
		string+=" $(cat /etc/revdep-rebuild/05cross-${CTARGET}|sed -e 's/SEARCH_DIRS_MASK=//')"
	fi
	printf "$string">05cross-${CTARGET}
	doins 05cross-${CTARGET}
}

# Move around the libs to the right location.  For some reason,
# when installing gcc, it dumps internal libraries into /usr/lib
# instead of the private gcc lib path
gcc_movelibs() {

	# For non-target libs which are for CHOST and not CTARGET, we want to
	# move them to the compiler-specific CHOST internal dir.  This is stuff
	# that you want to link against when building tools rather than building
	# code to run on the target.
	if is_crosscompile ; then
		dodir "${HOSTLIBPATH#${EPREFIX}}"
		mv "${ED}"/usr/$(get_libdir)/libcc1* "${D}${HOSTLIBPATH}" || die
	fi

	# For all the libs that are built for CTARGET, move them into the
	# compiler-specific CTARGET internal dir.
	local x multiarg removedirs=""
	for multiarg in $($(XGCC) -print-multi-lib) ; do
		multiarg=${multiarg#*;}
		multiarg=${multiarg//@/ -}

		local OS_MULTIDIR=$($(XGCC) ${multiarg} --print-multi-os-directory)
		local MULTIDIR=$($(XGCC) ${multiarg} --print-multi-directory)
		local TODIR="${D}${LIBPATH}"/${MULTIDIR}
		local FROMDIR=

		[[ -d ${TODIR} ]] || mkdir -p ${TODIR}

		for FROMDIR in \
			"${LIBPATH}"/${OS_MULTIDIR} \
			"${LIBPATH}"/../${MULTIDIR} \
			"${PREFIX}"/lib/${OS_MULTIDIR} \
			"${PREFIX}"/${CTARGET}/lib/${OS_MULTIDIR}
		do
			removedirs="${removedirs} ${FROMDIR}"
			FROMDIR=${D}${FROMDIR}
			if [[ ${FROMDIR} != "${TODIR}" && -d ${FROMDIR} ]] ; then
				local files=$(find "${FROMDIR}" -maxdepth 1 ! -type d 2>/dev/null)
				if [[ -n ${files} ]] ; then
					mv ${files} "${TODIR}" || die
				fi
			fi
		done
		fix_libtool_libdir_paths "${LIBPATH}/${MULTIDIR}"

		# SLOT up libgcj.pc if it's available (and let gcc-config worry about links)
		FROMDIR="${PREFIX}/lib/${OS_MULTIDIR}"
		for x in "${D}${FROMDIR}"/pkgconfig/libgcj*.pc ; do
			[[ -f ${x} ]] || continue
			sed -i "/^libdir=/s:=.*:=${LIBPATH}/${MULTIDIR}:" "${x}" || die
			mv "${x}" "${D}${FROMDIR}"/pkgconfig/libgcj-${GCC_PV}.pc || die
		done
	done

	# We remove directories separately to avoid this case:
	#	mv SRC/lib/../lib/*.o DEST
	#	rmdir SRC/lib/../lib/
	#	mv SRC/lib/../lib32/*.o DEST  # Bork
	for FROMDIR in ${removedirs} ; do
		rmdir "${D}"${FROMDIR} >& /dev/null
	done
	find -depth "${ED}" -type d -exec rmdir {} + >& /dev/null
}
				
src_install() {
	cd ${WORKDIR}/build

# PRE-MAKE INSTALL SECTION:

	# Don't allow symlinks in private gcc include dir as this can break the build
	( set +f ; find gcc/include*/ -type l -delete 2>/dev/null )

	# Remove generated headers, as they can cause things to break
	# (ncurses, openssl, etc).
	while read x; do
		grep -q 'It has been auto-edited by fixincludes from' "${x}" \
			&& echo "Removing auto-generated header: $x" \
			&& rm -f "${x}"
	done < <(find gcc/include*/ -name '*.h')

# MAKE INSTALL SECTION:

	make -j1 DESTDIR="${D}" install || die

# POST MAKE INSTALL SECTION:
	if is_crosscompile; then
		cross_toolchain_env_setup
	else
		# Basic sanity check
		local EXEEXT
		eval $(grep ^EXEEXT= "${WORKDIR}"/build/gcc/config.log)
		[[ -r ${D}${BINPATH}/gcc${EXEEXT} ]] || die "gcc not found in ${D}"

		# Install compat wrappers
		exeinto "${DATAPATH}"
		( set +f ; doexe "${FILESDIR}"/c{89,99} || die )	
	fi
	
	# Setup env.d entry 
	dodir /etc/env.d/gcc
	create_gcc_env_entry

# CLEANUPS:

	# Punt some tools which are really only useful while building gcc
	find "${D}" -name install-tools -prune -type d -exec rm -rf "{}" \; 2>/dev/null
	# This one comes with binutils
	find "${D}" -name libiberty.a -delete 2>/dev/null
	# prune empty dirs left behind
	find "${D}" -depth -type d -delete 2>/dev/null
	# ownership fix:
	chown -R root:0 "${D}"${LIBPATH} 2>/dev/null

	gcc_movelibs

	linkify_compiler_binaries
	tasteful_stripping
	
	# Remove python files in the lib path
	find "${D}/${LIBPATH}" -name "*.py" -type f -exec rm "{}" \; 2>/dev/null
	
	# Remove unwanted docs and prepare the rest for installation
	doc_cleanups
	
	# Cleanup undesired libtool archives
	find "${D}" \
		'(' \
			-name 'libstdc++.la' -o -name 'libstdc++fs.la' -o -name 'libsupc++.la' -o \
			-name 'libcc1.la' -o -name 'libcc1plugin.la' -o -name 'libcp1plugin.la' -o \
			-name 'libgomp.la' -o -name 'libgomp-plugin-*.la' -o \
			-name 'libgfortran.la' -o -name 'libgfortranbegin.la' -o \
			-name 'libmpx.la' -o -name 'libmpxwrappers.la' -o \
			-name 'libitm.la' -o -name 'libvtv.la' -o -name 'lib*san.la' \
		')' -type f -delete 2>/dev/null

	# replace gcc_movelibs - currently handles only libcc1:
	( set +f
		einfo -- "Removing extraneous libtool '.la' files from '${PREFIX}/lib*}'."
		rm ${D%/}${PREFIX}/lib{,32,64}/*.la 2>/dev/null
		einfo -- "Relocating libs to '${LIBPATH}':"
		for l in "${D%/}${PREFIX}"/lib{,32,64}/* ; do
			[ -f "${l}" ] || continue
			mydir="${l%/*}" ; myfile="${l##*/}"
			einfo -- "Moving '${myfile}' from '${mydir#${D}}' to '${LIBPATH}'."
			cd "${mydir}" && mv "${myfile}" "${D}${LIBPATH}/${myfile}" 2>/dev/null || die
		done
	)

	# the .la files that are installed have weird embedded single quotes around abs
	# paths on the dependency_libs line. The following code finds and fixes them:

	for x in $(find ${D}${LIBPATH} -iname '*.la'); do
		dep="$(cat $x | grep ^dependency_libs)"
		[ "$dep" == "" ] && continue
		inner_dep="${dep#dependency_libs=}"
		inner_dep="${inner_dep//\'/}"
		inner_dep="${inner_dep# *}"
		sed -i -e "s:^dependency_libs=.*$:dependency_libs=\'${inner_dep}\':g" $x || die
	done

	# Don't scan .gox files for executable stacks - false positives
	if use go; then
		export QA_EXECSTACK="${PREFIX#/}/lib*/go/*/*.gox"
		export QA_WX_LOAD="${PREFIX#/}/lib*/go/*/*.gox"
	fi

	# Disable RANDMMAP so PCH works.
	[[ ! is_crosscompile ]] && \
		pax-mark -r "${D}${PREFIX}/libexec/gcc/${CTARGET}/${GCC_CONFIG_VER}/cc1" ; \
		pax-mark -r "${D}${PREFIX}/libexec/gcc/${CTARGET}/${GCC_CONFIG_VER}/cc1plus"
}

pkg_postrm() {
	# clean up the cruft left behind by cross-compilers
	if is_crosscompile ; then
		if [[ -z $(ls "${ROOT}etc/env.d/gcc"/${CTARGET}* 2>/dev/null) ]] ; then
			( set +f
				rm -f "${ROOT}etc/env.d/gcc"/config-${CTARGET} 2>/dev/null
				rm -f "${ROOT}etc/env.d"/??gcc-${CTARGET} 2>/dev/null
				rm -f "${ROOT}usr/bin"/${CTARGET}-{gcc,{g,c}++}{,32,64} 2>/dev/null
			)
		fi
		return 0
	fi
}

pkg_postinst() {
	if is_crosscompile; then
			mkdir -p "${ROOT}etc/env.d"
			cat > "${ROOT}etc/env.d/05gcc-${CTARGET}" <<- EOF
				PATH=${BINPATH}
				ROOTPATH=${BINPATH}
			EOF
	fi

	# hack from gentoo - should probably be handled better:
	( set +f ; cp "${ROOT}${DATAPATH}"/c{89,99} "${ROOT}${PREFIX}/bin/" 2>/dev/null )

	PATH="${BINPATH}:${PATH}"
	export PATH
	compiler_auto_enable ${PV} ${CTARGET}
}
