# Distributed under the terms of the GNU General Public License v2

# See README.txt for usage notes.

EAPI=6

inherit flag-o-matic multilib-build eutils pax-utils toolchain-enable toolchain-funcs git-r3

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
IUSE="$IUSE +fortify_source +link_now +pie vtv" # Extra hardening flags
IUSE="$IUSE +stack_clash_protection" # Stack clash protector added in gcc-8
IUSE="$IUSE sanitize dev_extra_warnings" # Dev flags
IUSE="$IUSE systemtap valgrind zstd" # TODO: sort these flags
IUSE="$IUSE checking_release checking_yes checking_all"

# Version of archive before patches.
GCC_ARCHIVE_VER="10.2.0"
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
        29_all_lto-intl-workaround-PR95194.patch
        30_all_plugin-objdump.patch
        31_all_fno-delayed-branch.patch
        32_all_sparc_pie_TEXTREL.patch
        33_all_lto-O0-mix-ICE-ipa-PR96291.patch
        34_all_fundecl-ICE-PR95820.patch
)

# Ada Support:
GNAT32="gnat-gpl-2014-x86-linux-bin.tar.gz"
GNAT64="gnat-2020-20200429-x86_64-linux-bin.tar.gz"
SRC_URI="
        $SRC_URI
        ada? (
                amd64? ( https://community.download.adacore.com/v1/4d99b7b2f212c8efdab2ba8ede474bb9fa15888d?filename=${GNAT64} -> ${GNAT64} )
                x86? (  https://community.download.adacore.com/v1/c5e9e6fdff5cb77ed90cf8c62536653e27c0bed6?filename=${GNAT32} -> ${GNAT32} )
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

gcc-abi-map() {
	# Convert the ABI name we use in Gentoo to what gcc uses
	local map=()
	case ${CTARGET} in
	mips*)
	    map=("o32 32" "n32 n32" "n64 64")
	    ;;
	riscv*)
	    map=("lp64d lp64d" "lp64 lp64")
	    ;;
	x86_64*)
	    map=("amd64 m64" "x86 m32" "x32 mx32")
	    ;;
	esac

	local m
	for m in "${map[@]}" ; do
		l=( ${m} )
		[[ $1 == ${l[0]} ]] && echo ${l[1]} && break
	done
}

XGCC() {
    get_make_var GCC_FOR_TARGET ;
}

# Grab a variable from the build system (taken from linux-info.eclass)
get_make_var() {
        local var=$1 makefile=${2:-${WORKDIR}/build/Makefile}
        echo -e "e:\\n\\t@echo \$(${var})\\ninclude ${makefile}" | \
                r=${makefile%/*} emake --no-print-directory -s -f - 2>/dev/null
}

# This is a historical wart.  The original Gentoo/amd64 port used:
#    lib32 - 32bit binaries (x86)
#    lib64 - 64bit binaries (x86_64)
#    lib   - "native" binaries (a symlink to lib64)
# Most other distros use the logic (including mainline gcc):
#    lib   - 32bit binaries (x86)
#    lib64 - 64bit binaries (x86_64)
# Over time, Gentoo is migrating to the latter form.
#
# Unfortunately, due to distros picking the lib32 behavior, newer gcc
# versions will dynamically detect whether to use lib or lib32 for its
# 32bit multilib.  So, to keep the automagic from getting things wrong
# while people are transitioning from the old style to the new style,
# we always set the MULTILIB_OSDIRNAMES var for relevant targets.
setup_multilib_osdirnames() {
        is_multilib || return 0

        local config
        local libdirs="../lib64 ../lib32"

        # this only makes sense for some Linux targets
        case ${CTARGET} in
        x86_64*-linux*)    config="i386" ;;
        powerpc64*-linux*) config="rs6000" ;;
        sparc64*-linux*)   config="sparc" ;;
        s390x*-linux*)     config="s390" ;;
        *)                     return 0 ;;
        esac
        config+="/t-linux64"

        local sed_args=()

        sed_args+=( -e 's:$[(]call if_multiarch[^)]*[)]::g' )

        einfo "updating multilib directories to be: ${libdirs}"
        if tc_version_is_at_least 4.6.4 || tc_version_is_at_least 4.7 ; then
                sed_args+=( -e '/^MULTILIB_OSDIRNAMES.*lib32/s:[$][(]if.*):../lib32:' )
        else
                sed_args+=( -e "/^MULTILIB_OSDIRNAMES/s:=.*:= ${libdirs}:" )
        fi

        sed -i "${sed_args[@]}" "${S}"/gcc/config/${config} || die
}

# General purpose version check.  Without a second arg matches up to minor version (x.x.x)
tc_version_is_at_least() {
        ver_test "${2:-${GCC_ARCHIVE_VER}}" -ge "$1"
}


is_multilib() {
	tc_version_is_at_least 3 || return 1
	use_if_iuse multilib
}

pkg_pretend() {

    # Initial check
    if use vanilla && use hardened; then
        die "vanilla and hardened USE flags are incompatible - Disable one of them."
    fi

    # Some features require C++, so check that requirement is met when the relevant USE flags are selected.
    if ! use cxx; then
        if use ada; then
            die "Ada requires a C++ compiler, set USE=cxx to continue."
        fi

        if use go; then
            die "Go requires a C++ compiler, set USE=cxx to continue."
        fi

        if use objc++; then
            die "Obj-C++ requires a C++ compiler, set USE=cxx to continue."
        fi
    fi
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
    # 8) Configure TARGET_LIBC and export.

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

    # Todo
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

	# Flags to be used to build stage one compiler.
	STAGE1_CFLAGS="${STAGE1_CFLAGS:--O2 -pipe}"

	# Flags to be used for stages two and three.
	# TODO: allow custom optimisation levels -O3 and -Os
	BOOT_CFLAGS="${BOOT_CFLAGS:--O2 -pipe $(get_abi_CFLAGS ${TARGET_DEFAULT_ABI})}"

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

    # Now for GCC_TARGET... only perform a three stage and any additional bootstraps if != cross_compiler.
	if ! is_crosscompile && use bootstrap; then
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

	# For some reason, when upgrading gcc, the gcc Makefile will install stuff
	# like crtbegin.o into a subdirectory based on the name of the currently-installed
	# gcc version, rather than *our* gcc version. Manually fix this:

	sed -i -e "s/^version :=.*/version := ${GCC_CONFIG_VER}/" ${S}/libgcc/Makefile.in || die

	# make sure the pkg config files install into multilib dirs.
	# since we configure with just one --libdir, we can't use that (as gcc itself takes care of building multilibs).
	# Gentoo Linux bug #435728
	find "${S}" -name Makefile.in -exec sed -i '/^pkgconfigdir/s:=.*:=$(toolexeclibdir)/pkgconfig:' {} +

	# update configure files
	local f
	einfo "Fixing misc issues in configure files"
	for f in $(grep -l 'autoconf version 2.13' $(find "${S}" -name configure)) ; do
		ebegin "  Updating ${f/${S}\/} [LANG]"
		patch "${f}" "${FILESDIR}"/gcc-configure-LANG.patch >& "${T}"/configure-patch.log || eerror "Please file a bug about this"
		eend $?
	done

	# === OSDIRNAMES ===

    setup_multilib_osdirnames

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
            eapply "${FILESDIR}/xor-patches/${GCC_ARCHIVE_VER}/03_all_ENABLE_DEFAULT_SSP_ALL-fstack-protector-all.patch" || die "patch fail"
            gcc_hard_flags+=" -DENABLE_DEFAULT_SSP_ALL "
        fi

        # Enable FORTIFY_SOURCE by default
        if use fortify_source; then
             eapply_gentoo "$(set +f ; cd "${GENTOO_PATCHES_DIR}" && echo ??_all_default-fortify-source.patch )"
        fi

        # Enable LINK_NOW by default
        if use link_now; then
            eapply "${FILESDIR}/xor-patches/${GCC_ARCHIVE_VER}/01_all_ENABLE_DEFAULT_LINK_NOW-z-now.patch" || die "patch fail"
            gcc_hard_flags+=" -DENABLE_DEFAULT_LINK_NOW "
        fi

	    # Enable Stack Clash Protection by default
	    if use stack_clash_protection; then
	        eapply "${FILESDIR}/xor-patches/${GCC_ARCHIVE_VER}/02_all_ENABLE_DEFAULT_SCP-fstack-clash-protection.patch" || die "patch fail"
	        gcc_hard_flags+=" -DENABLE_DEFAULT_SCP "
	    fi

	    # GCC stores it's CFLAGS in the Makefile - here we make those CFLAGS == ${gcc_hard_flags} so that they are applied in the build process.
        sed -e '/^ALL_CFLAGS/iHARD_CFLAGS = '  -e 's|^ALL_CFLAGS = |ALL_CFLAGS = $(HARD_CFLAGS) |' -i "${S}"/gcc/Makefile.in
        sed -e '/^ALL_CXXFLAGS/iHARD_CFLAGS = '  -e 's|^ALL_CXXFLAGS = |ALL_CXXFLAGS = $(HARD_CFLAGS) |' -i "${S}"/gcc/Makefile.in

        # write HARD_CFLAGS back to the gcc Makefile.
        sed -i -e "/^HARD_CFLAGS = /s|=|= ${gcc_hard_flags} |" "${S}"/gcc/Makefile.in || die
	fi

	# === CROSS COMPILER ===
	is_crosscompile && _gcc_prepare_cross

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

_gcc_prepare_cross() {

	# if we don't tell it where to go, libcc1 stuff ends up in ${ROOT}/usr/lib (or rather dies colliding)
	sed -e 's%cc1libdir = .*%cc1libdir = '"${ROOT}${PREFIX}"'/$(host_noncanonical)/$(target_noncanonical)/lib/$(gcc_version)%' \
		-e 's%plugindir = .*%plugindir = '"${ROOT}${PREFIX}"'/lib/gcc/$(target_noncanonical)/$(gcc_version)/plugin%' \
		-i "${WORKDIR}/${P}/libcc1"/Makefile.{am,in}
	if [[ ${CTARGET} == avr* ]]; then
		sed -e 's%native_system_header_dir=/usr/include%native_system_header_dir=/include%' -i "${WORKDIR}/${P}/gcc/config.gcc"
	fi
}

src_configure() {

    ### INFO ###

    # Configure procedure is as follows
    #
    # 1) Branding
    # 2) General (paths etc)
    # 3) Languages
    # 4) CHOST / CBUILD / CTARGET
    # 5) Cross compiling
    # 6) libc
    # 7) Arch
    # 8) Features and libraries

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

    # === GENERAL CONFIGURATION ===

    # Set up paths
    #--libdir=${LIBPATH}/lib <<< todo: investigate
    confgcc+=(
        --prefix=${PREFIX}
        --bindir=${BINPATH}
        --includedir=${LIBPATH}/include
        --datadir=${DATAPATH}
        --mandir=${DATAPATH}/man
        --infodir=${DATAPATH/info}
        --with-gxx-include-dir=${STDCXX_INCDIR}
        # Stick the python scripts in their own slotted directory (Gentoo Linux bug #279252)
        #
        #  Specifies where to install the Python modules used for aot-compile.
        # DIR should not include the prefix used in installation.
        # e.g. --with-python-dir=/lib/python2.5/site-packages == /usr/lib/python2.5/site-packages
        #
        # This should translate into "/share/gcc-data/${CTARGET}/${GCC_CONFIG_VER}/python"
        --with-python-dir=${DATAPATH/$PREFIX/}/python
    )

    # TODO
    confgcc+=(
        --enable-obsolete
        --disable-werror
        --enable-secureplt
        --with-system-zlib
        --disable-libunwind-exceptions
        --enable-version-specific-runtime-libs
    )

    # Allow gcc to search for clock funcs in the main c library.
    # If it can't find them, then tough cookies, we aren't going to link in -lrt to all c++ programs.
    # Gentoo Linux bug #411681
    if use cxx; then
        confgcc+=( --enable-libstdcxx-time )
    fi

    # These checks perform internal consistency checks within gcc, but adds error checking of the requested complexity.
    #
    # checking=release performs checks on assert + compiler runtime, and is fairly cheap.
    # checking=all performs all available tests except 'valgrind', and is fairly expensive.
    #
    # See https://gcc.gnu.org/install/configure.html for further information on the checks available within gcc.
    #
    # NOTE: '--enable-stage1-checking=...' == ''--enable-checking=...' unless explicitly specified.
    # NOTE2: '--enable-checking=release' is default $upstream unless disabled via '--enable-checking=no'.
    # NOTE3: gcc upstream doesn't test '--disable-checking', preferring '--enable-checking=no'. SEE: Gentoo Linux #31721
    # NOTE4: checking=release ==  'assert, runtime'
    #        checking=yes == 'assert, misc, gc, gimple, rtlflag, runtime, tree, types'
    #        checking=all == 'assert, df, extra, fold, gc, gcac, gimple, misc, rtl, rtlflag, runtime, tree, types'
    if use checking_release; then
        confgcc+=( --enable-checking=release )
    elif use checking_yes; then
        confgcc+=( --enable-checking=yes )
    elif use checking_all; then
        confgcc+=( --enable-checking=all )
    else
        confgcc+=( --enable-checking=no )
    fi

    # === END GENERAL CONFIGURATION ===

    # === LANGUAGE CONFIGURATION ===

	# C/C++ used for stage1 compiler
	# TODO: can this be changed to c only?
	local GCC_LANG="c,c++"

	if use objc; then
		GCC_LANG+=",objc"
		use objc-gc && confgcc+=( --enable-objc-gc )
		use objc++ && GCC_LANG+=",obj-c++"
	fi

	use fortran && GCC_LANG+=",fortran" || confgcc+=( --disable-libquadmath )

	use go && GCC_LANG+=",go"

	use ada && GCC_LANG+=",ada" && conf_gcc_lang+=" CC=${GNATBOOT}/bin/gcc CXX=${GNATBOOT}/bin/g++ AR=${GNATBOOT}/bin/gcc-ar AS=as LD=ld NM=${GNATBOOT}/bin/gcc-nm RANLIB=${GNATBOOT}/bin/gcc-ranlib"

	use d && GCC_LANG+=",d"

    if use lto; then
        GCC_LANG+=",lto"
    fi

    # and now add the GCC_LANG array to confgcc
	confgcc+=(
	    --enable-languages=${GCC_LANG}
	    --disable-libgcj
	)

    # === END LANGUAGE CONFIGURATION ===

	# === CHOST / CBUILD / CTARGET ===

    # Set the CHOST.
	confgcc+=( --host=${CHOST} )

    # Set the CTARGET if we are cross compiling.
	if is_crosscompile || tc-is-cross-compiler; then
		# Straight from the GCC install doc:
		# "GCC has code to correctly determine the correct value for target for nearly all native systems.
		# Therefore, we highly recommend you not provide a configure target when configuring a native compiler."
		confgcc+=( --target=${CTARGET} )
	fi

	# TODO: set CBUILD etc for is_canadian_cross and is_cross_build

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
            # libquadmath requires a libc, Gentoo Linux bug #734820
            confgcc+=( --disable-shared --disable-libatomic --disable-libquadmath --disable-threads --without-headers --disable-libstdcxx )
        elif has_version "${CATEGORY}/${TARGET_LIBC}[headers-only]"; then
            # libc installed, but has USE="crosscompile_opts_headers-only" to only install headers:
            confgcc+=( --disable-shared --disable-libatomic --with-sysroot=${PREFIX}/${CTARGET} --disable-libstdcxx )
        else
            # libc is installed:
            confgcc+=( --with-sysroot=${PREFIX}/${CTARGET} --enable-libstdcxx-time )
        fi

    else
		# handle bootstrap here as we can only perform a three stage and any additional bootstraps if native...
        # three stage bootstrapping doesnt quite work when you cant run the resulting binaries natively!
		if use bootstrap; then
		    confgcc+=( --enable-bootstrap --enable-shared )
		else
		    confgcc+=( --disable-bootstrap )
		fi

		if use openmp; then
		    confgcc+=( --enable-libgomp )
		else
		    confgcc+=( --disable-libgomp )
		fi

        # CHOST specific options
		case ${CHOST} in
            mingw*|*-mingw*)
                # mingw requires win32 threads
                confgcc+=( --enable-threads=win32 )
                ;;
            *)
                # default to posix threads for all other CHOST
                confgcc+=( --enable-threads=posix )
                ;;
		esac
    fi

    # === END CROSS COMPILER ===

    # === LIBC CONFIGURATION ===

 	# __cxa_atexit is "essential for fully standards-compliant handling of destructors", but apparently requires glibc.
	case ${CTARGET} in
        *-uclibc*)
            if tc_has_feature nptl ; then
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

	# === ARCH CONFIGURATION ===

    # multilib
    if use multilib; then
        confgcc+=( --enable-multilib )
    else
    	# Fun times: if we are building for a target that has multiple
		# possible ABI formats, and the user has told us to pick one
		# that isn't the default, then not specifying it via the list
		# below will break that on us.
        confgcc+=( --disable-multilib )
    fi

    # translate our notion of multilibs into gcc's
	local abi list
	for abi in $(get_all_abis TARGET) ; do
		local l=$(gcc-abi-map ${abi})
		[[ -n ${l} ]] && list+=",${l}"
	done
	if [[ -n ${list} ]] ; then
		case ${CTARGET} in
		x86_64*)
			confgcc+=( --with-multilib-list=${list:1} )
			;;
		esac
	fi

    # multiarch
    if use multiarch; then
        confgcc+=( --enable-multiarch )
    else
        confgcc+=( --disable-multiarch )
    fi

    if ! use generic_host; then
        confgcc+="${MARCH:+ --with-arch=${MARCH}}${MCPU:+ --with-cpu=${MCPU}}${MTUNE:+ --with-tune=${MTUNE}}${MFPU:+ --with-fpu=${MFPU}}"
    fi

	local with_abi_map=()
	case $(tc-arch) in
        arm)	#264534 #414395
            local a arm_arch=${CTARGET%%-*}
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
                confgcc+=( --with-arch=${arm_arch} )
            fi

            # Make default mode thumb for microcontroller classes
            # Gentoo Linux bug #418209
            [[ ${arm_arch} == *-m ]] && confgcc+=( --with-mode=thumb )

            # Follow the new arm hardfp distro standard by default
            local float="hard"
            local default_fpu=""

            case ${CTARGET} in
                *[-_]softfloat[-_]*)
                    float="soft"
                    ;;
                *[-_]softfp[-_]*)
                    float="softfp"
                    ;;
                armv[56]*)
                    default_fpu="vfpv2"
                    ;;
                armv7ve*)
                    default_fpu="vfpv4-d16"
                    ;;
                armv7*)
                    default_fpu="vfpv3-d16"
                    ;;
                amrv8*)
                    default_fpu="fp-armv8"
                    ;;
            esac

            # Pass args to configure
            confgcc+=( --with-float=$float )

            if [ -z "${MFPU}" ] && [ -n "${default_fpu}" ]; then
                confgcc+=( --with-fpu=${default_fpu} )
            fi

            ;;
        mips)
            # Add --with-abi flags to set default ABI
            confgcc+=( --with-abi=$(gcc-abi-map ${TARGET_DEFAULT_ABI}) )
            ;;
        amd64)
            # drop the older/ABI checks once this get's merged into some version of gcc upstream
            confgcc+=( --with-abi=$(gcc-abi-map ${TARGET_DEFAULT_ABI}) )
            ;;
        x86)
            # Default arch for x86 is normally i386, lets give it a bump since glibc will do so based on CTARGET anyways
            confgcc+=( --with-arch=${CTARGET%%-*} )
            ;;
        hppa)
            # Enable sjlj exceptions for backward compatibility on hppa
            [[ ${GCCMAJOR} == "3" ]] && confgcc+=( --enable-sjlj-exceptions )
            ;;
        ppc)
            # Set up defaults based on current CFLAGS
            is-flagq -mfloat-gprs=double && confgcc+=( --enable-e500-double )
            [[ ${CTARGET//_/-} == *-e500v2-* ]] && confgcc+=( --enable-e500-double )
            ;;
        ppc64)
            # On ppc64 big endian target gcc assumes elfv1 by default,
            # and elfv2 on little endian
            # but musl does not support elfv1 at all on any endian ppc64
            # see https://git.musl-libc.org/cgit/musl/tree/INSTALL
            # https://bugs.gentoo.org/704784
            # https://gcc.gnu.org/PR93157
            [[ ${CTARGET} == powerpc64-*-musl ]] && confgcc+=( --with-abi=elfv2 )
            ;;
        riscv)
            # Add --with-abi flags to set default ABI
            confgcc+=( --with-abi=$(gcc-abi-map ${TARGET_DEFAULT_ABI}) )
            ;;
	esac

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

    # ada
    if use ada; then
        confgcc+=( --disable-libada)
    fi

    # graphite todo
    if use graphite; then
        confgcc+=( --with-isl --disable-isl-version-check )
    else
        confgcc+=( --without-isl )
    fi

    # can this be shit canned? is solaris only, and i have better things to do with my time than support that
    use libssp || export gcc_cv_libc_provides_ssp=yes
    if use libssp; then
        confgcc+=( --enable-libssp )

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

    if ! use pch; then
        confgcc+=( --disable-libstdcxx-pch )
    fi

    # Default building of PIE executables.
    if use pie; then
        confgcc+=( --enable-default-pie )
    else
        confgcc+=( --disable-default-pie )
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

    # === END FEATURE / LIBRARY CONFIGURATION ===

	# Pass any local EXTRA_ECONF from /etc/portage/env to ./configure.
    confgcc+=( "$@" ${EXTRA_ECONF} )

    # Pass BUILD_CONFIG to ./configure.
    confgcc+=( --with-build-config=${BUILD_CONFIG} )

	# Create build directory...
	mkdir -p "${WORKDIR}"/build || die "create build directory failed"

	# ... and cd to the newly created build directory.
	cd "${WORKDIR}"/build || die "cd to build directory failed"

    # Nothing wrong with a bit of verbosity
	echo
	einfo "PREFIX:          ${PREFIX}"
	einfo "BINPATH:         ${BINPATH}"
	einfo "LIBPATH:         ${LIBPATH}"
	einfo "INCLUDEPATH:     ${LIBPATH}/include"
	einfo "DATAPATH:        ${DATAPATH}"
	einfo "STDCXX_INCDIR:   ${STDCXX_INCDIR}"
	echo
	einfo "Languages:       ${GCC_LANG}"
	echo
	einfo "Configuring GCC with: ${confgcc[@]//--/\n\t--}"
	echo

	# todo: force use of bash here? old gcc versions do not detect bash and re-exec itself.

    # finally run ./configure!
	../gcc-${PV}/configure \
	    "${confgcc[@]}" || die "failed to run configure"

	    is_crosscompile && gcc_conf_cross_post
}

gcc_conf_cross_post() {
	if use arm ; then
		sed -i "s/none-/${CHOST%%-*}-/g" ${WORKDIR}/build/Makefile || die
	fi

}

src_compile() {

    # Unset ABI
    # leftover from Funtoo - needed?
	unset ABI

	# To compile ada library standard files special compiler options are passed via ADAFLAGS in the Makefile.
	# Unset ADAFLAGS as setting this override the options...
	unset ADAFLAGS

	einfo "Compiling ${PN} (${GCC_TARGET})..."

	# Run make against GCC_TARGET, setting some variables as required.
	emake -C "${WORKDIR}"/build \
            LDFLAGS="${LDFLAGS}" \
            STAGE1_CFLAGS="${STAGE1_CFLAGS}" \
            BOOT_CFLAGS="${BOOT_CFLAGS}" \
	        LIBPATH="${LIBPATH}" \
            ${GCC_TARGET} || die "emake failed with ${GCC_TARGET}"

    if use ada; then
		# Without these links it is not getting the good compiler
		# Need to check why...
		ln -s gcc ../build/prev-gcc || die
		ln -s ${CHOST} ../build/prev-${CHOST} || die
		# Building standard ada library
		emake -C gcc gnatlib-shared
		# Building gnat toold
		emake -C gcc gnattools
    fi

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
		env RESTRICT="" CHOST=${CHOST} prepstrip "${D}${BINPATH}" ; \
		env RESTRICT="" CHOST=${CTARGET} prepstrip "${D}${LIBPATH}"
	# gcc used to install helper binaries in lib/ but then moved to libexec/
	[[ -d ${D}${PREFIX}/libexec/gcc ]] && \
		env RESTRICT="" CHOST=${CHOST} prepstrip "${D}${PREFIX}/libexec/gcc/${CTARGET}/${GCC_CONFIG_VER}"
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

src_install() {

    # Change to the build directory
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
