# Distributed under the terms of the GNU General Public License v2

# See README.txt for usage notes.

EAPI=7

inherit eutils flag-o-matic libtool multilib-build pax-utils toolchain-funcs

DESCRIPTION="The GNU Compiler Collection"
HOMEPAGE="https://gcc.gnu.org/"

LICENSE="GPL-3+ LGPL-3+ || ( GPL-3+ libgcc libstdc++ gcc-runtime-library-exception-3.1 ) FDL-1.3+"
KEYWORDS="~amd64"

SLOT="${PV%%.*}"

RESTRICT="strip"

IUSE="ada +cxx d go +fortran jit objc objc++ objc-gc " # Languages
IUSE="$IUSE bpf nvptx" # 'foreign' target support
IUSE="$IUSE debug  test" # Run tests
IUSE="$IUSE doc nls hardened +multilib multiarch" # docs/i18n/system flags
IUSE="$IUSE custom-cflags openmp fixed-point graphite lto pch +quad-math" # Optimizations/features flags
IUSE="$IUSE +bootstrap pgo +system-bootstrap" # Bootstrap flags
IUSE="$IUSE +pie libssp +ssp" # Base hardening flags
IUSE="$IUSE cet +fortify_source +bind_now vtv" # Extra hardening flags
IUSE="$IUSE +scp" # Stack clash protector added in gcc-8
IUSE="$IUSE asan sanitize ubsan dev_extra_warnings" # Dev flags
IUSE="$IUSE nptl systemtap valgrind zstd" # TODO: sort these flags
IUSE="$IUSE +checking_release checking_yes checking_all" # gcc internal checking

BDEPEND="
	sys-devel/binutils
	>=sys-devel/bison-1.875
	doc? ( >=app-doc/doxygen-1.7 )
	>=sys-devel/flex-2.5.4
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
	sanitize? ( virtual/libcrypt )
	zstd? ( app-arch/zstd )
	bpf? ( sys-devel/binutils[bpf] )
	nvptx? ( sys-devel/nvptx-tools )
"

DEPEND="
	${RDEPEND}
"

PDEPEND="
	>=sys-devel/gcc-config-2.3
	>=sys-devel/libtool-2.4.3
"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="
		${PDEPEND}
		elibc_glibc? ( >=sys-libs/glibc-2.8 )
		elibc_musl? ( sys-libs/musl )
	"
fi

REQUIRED_USE="
	ada? ( cxx )
	asan? ( sanitize )
	cet? ( amd64 )
	go? ( cxx )
	objc++? ( cxx )
	fortran? ( quad-math )
	ubsan? ( sanitize )
	?? ( checking_release checking_yes checking_all )
"

GCC_MAJOR="${PV%%.*}"
# Version of archive before patches.
GCC_ARCHIVE_VER="${PV%%_*}"
# GCC release archive
GCC_A="gcc-${GCC_ARCHIVE_VER}.tar.xz"

SRC_URI="
	https://gcc.gnu.org/pub/gcc/releases/gcc-${GCC_ARCHIVE_VER}/${GCC_A}
"

S="${WORKDIR}/gcc-${GCC_ARCHIVE_VER}"

GENTOO_PATCHES_DIR="${FILESDIR}/${GCC_ARCHIVE_VER}/gentoo-patches"

# Disable a few of these as they will be toggled by USE flag, i.e 01, 02, 03, 27 + 28.
GENTOO_PATCHES=(
#	01_all_default-fortify-source.patch
#	02_all_default-warn-format-security.patch
#	03_all_default-warn-trampolines.patch
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
#	27_all_EXTRA_OPTIONS-z-now.patch
#	28_all_EXTRA_OPTIONS-fstack-clash-protection.patch
	29_all_lto-intl-workaround-PR95194.patch
	30_all_plugin-objdump.patch
	31_all_fno-delayed-branch.patch
	32_all_vtv-slibtool.patch
	33_all_ctor-union-PR100489.patch
	34_all_ICE-tsubst-PR100102.patch
	35_all_remove-cyclades.patch
)

CAIRN_PATCHES_DIR="${FILESDIR}/${GCC_ARCHIVE_VER}/cairn-patches"

CAIRN_PATCHES=(
#	01_all_ENABLE_DEFAULT_BIND_NOW-z-now.patch
#	02_all_ENABLE_DEFAULT_SCP-fstack-clash-protection.patch
#	03_all_ENABLE_DEFAULT_SSP_ALL-fstack-protector-all.patch
#	04_all_ENABLE_DEFAULT_CET.patch
	05_all_disable_float128_cuda.patch
)

ALPINE_PATCHES_DIR="${FILESDIR}/${GCC_ARCHIVE_VER}/alpine-patches"

# Disable a few of these as they will be toggled by USE flag, i.e 0003, 004, 0006 + 0007
# TODO: investigate 0008
ALPINE_PATCHES=(
	0001-posix_memalign.patch
	0002-gcc-poison-system-directories.patch
#	0003-Turn-on-Wl-z-relro-z-now-by-default.patch
#	0004-Turn-on-D_FORTIFY_SOURCE-2-by-default-for-C-C-ObjC-O.patch
	0005-On-linux-targets-pass-as-needed-by-default-to-the-li.patch
#	0006-Enable-Wformat-and-Wformat-security-by-default.patch
#	0007-Enable-Wtrampolines-by-default.patch
#	0008-Disable-ssp-on-nostdlib-nodefaultlibs-and-ffreestand.patch
	0009-Ensure-that-msgfmt-doesn-t-encounter-problems-during.patch
#	0010-Don-t-declare-asprintf-if-defined-as-a-macro.patch
	0011-libiberty-copy-PIC-objects-during-build-process.patch
	0012-libitm-disable-FORTIFY.patch
	0013-libgcc_s.patch
	0014-nopie.patch
	0015-libffi-use-__linux__-instead-of-__gnu_linux__-for-mu.patch
	0016-dlang-update-zlib-binding.patch
	0017-dlang-fix-fcntl-on-mips-add-libucontext-dep.patch
	0018-ada-fix-shared-linking.patch
#	0019-build-fix-CXXFLAGS_FOR_BUILD-passing.patch
	0020-add-fortify-headers-paths.patch
	0021-Alpine-musl-package-provides-libssp_nonshared.a.-We-.patch
	0022-DP-Use-push-state-pop-state-for-gold-as-well-when-li.patch
	0023-Pure-64-bit-MIPS.patch
	0024-use-pure-64-bit-configuration-where-appropriate.patch
	0025-always-build-libgcc_eh.a.patch
	0026-ada-libgnarl-compatibility-for-musl.patch
	0027-ada-musl-support-fixes.patch
	0028-gcc-go-Use-_off_t-type-instead-of-_loff_t.patch
	0029-gcc-go-Don-t-include-sys-user.h.patch
	0030-gcc-go-Fix-ucontext_t-on-PPC64.patch
	0031-gcc-go-Fix-handling-of-signal-34-on-musl.patch
	0032-gcc-go-Use-int64-type-as-offset-argument-for-mmap.patch
	0033-gcc-go-Fix-st_-a-m-c-tim-fields-in-generated-sysinfo.patch
	0034-gcc-go-signal-34-is-special-on-musl-libc.patch
	0035-gcc-go-Prefer-_off_t-over-_off64_t.patch
	0036-gcc-go-undef-SETCONTEXT_CLOBBERS_TLS-in-proc.c.patch
	0037-gcc-go-link-to-libucontext.patch
	0038-gcc-go-Disable-printing-of-unaccessible-ppc64-struct.patch
	0039-CRuntime_Musl-Support-v1.2.0-for-32-bits.patch
	0040-configure-Add-enable-autolink-libatomic-use-in-LINK_.patch
	0041-Use-generic-errstr.go-implementation-on-musl.patch
)

# TODO: This is a WIP. GNAT_AMD64_BOOTSTRAP currently works, and is a dynamically linked glibc built gcc.
# This will be replaced with a statically linked musl built gcc, possibly even with built-in math libraries etc to reduce error margin.
# Once the above has been completed, bootstrap binaries will be built for the other architectures.
GNAT_X86_BOOTSTRAP="todo"
GNAT_AMD64_BOOTSTRAP="gnatboot-10.2.0-amd64-glibc"
GNAT_ARM_BOOTSTRAP="todo"
GNAT_ARM64_BOOTSTRAP="todo"
GNAT_PPC_BOOTSTRAP="todo"
GNAT_PPC64_BOOTSTRAP="todo"
SRC_URI+="
	!system-bootstrap? (
		bootstrap? (
			ada? (
				amd64? (
					elibc_glibc? ( https://bitbucket.org/_x0r/xor-overlay/downloads/${GNAT_AMD64_BOOTSTRAP}.tar.xz )
				)
			)
		)
	)
"

# nvptx-none target requires newlib
NEWLIB_VER="4.1.0"
SRC_URI+="
	nvptx? ( https://github.com/mirror/newlib-cygwin/archive/refs/tags/newlib-${NEWLIB_VER}.tar.gz )
"

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
			map=("lp64d lp64d" "lp64 lp64" "ilp32d ilp32d" "ilp32 ilp32")
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

# Grab a variable from the build system (taken from linux-info.eclass)
get_make_var() {
	local var=$1 makefile=${2:-${WORKDIR}/build/Makefile}
	echo -e "e:\\n\\t@echo \$(${var})\\ninclude ${makefile}" | r=${makefile%/*} emake --no-print-directory -s -f - 2>/dev/null
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

	# this logic only current applies to glibc based systems
	if use multilib; then

		local config
		local libdirs="../lib64 ../lib32"

		# this only makes sense for some Linux targets
		case ${CTARGET} in
			x86_64*-linux*)
			    config="i386"
			    ;;
			powerpc64*-linux*)
			    config="rs6000"
			    ;;
			sparc64*-linux*)
			    config="sparc"
			    ;;
			s390x*-linux*)
			    config="s390"
			    ;;
			*)
			return 0
			;;
		esac

		config+="/t-linux64"

		local sed_args=()

		if tc_version_is_at_least 4.6; then
			sed_args+=( -e 's:$[(]call if_multiarch[^)]*[)]::g' )
		fi

		if [[ ${SYMLINK_LIB} == "yes" ]] ; then
			einfo "updating multilib directories to be: ${libdirs}"
			if tc_version_is_at_least 4.6.4 || tc_version_is_at_least 4.7 ; then
				sed_args+=( -e '/^MULTILIB_OSDIRNAMES.*lib32/s:[$][(]if.*):../lib32:' )
			else
				sed_args+=( -e "/^MULTILIB_OSDIRNAMES/s:=.*:= ${libdirs}:" )
			fi
		else
			einfo "using upstream multilib; disabling lib32 autodetection"
			sed_args+=( -r -e 's:[$][(]if.*,(.*)[)]:\1:' )
		fi

		sed -i "${sed_args[@]}" "${S}"/gcc/config/${config} || die "failed to set osdirnames"
	fi
}

# General purpose version check.  Without a second arg matches up to minor version (x.x.x)
tc_version_is_at_least() {
	ver_test "${2:-${GCC_ARCHIVE_VER}}" -ge "$1"
}

pkg_setup() {

	### INFO ###

	# Set up procedure is as follows:
	#
	# 1) Branding
	# 2) Unset GCC_SPECS and LANGUAGES.
	# 3) Set GCC_BRANCH_VER and GCC_CONFIG_VER.
	# 4) Capture / Filter / Downgrade FLAGS and ARCH where applicable.
	# 5) Set globals for TARGET_ABI, TARGET_DEFAULT_ABI and TARGET_MULTILIB_ABIS.
	# 6) Set and export STAGE1_CFLAGS and BOOT_CFLAGS.
	# 7) Configure BUILD_CONFIG and export.
	# 8) Configure GCC_TARGET and export.
	# 9) Configure TARGET_LIBC and export.

	if ! use hardened; then
		export GCC_BRANDING="Cairn Linux ${PV}"
	elif use hardened; then
		export GCC_BRANDING="Cairn Linux Hardened ${PV}"
	fi

	# we don't want to use the installed compiler's specs to build gcc!
	unset GCC_SPECS
	# Gentoo Linux bug #265283
	unset LANGUAGES

	# To compile ada library standard files special compiler options are passed via ADAFLAGS in the Makefile.
	# Unset ADAFLAGS as setting this override the options...
	unset ADAFLAGS

	# ADA_INCLUDE_PATH and ADA_OBJECT_PATH environment variables must not be set when building the Ada compiler, the Ada tools, or the Ada runtime libraries.
	# You can check that your build environment is clean by verifying that ‘gnatls -v’ lists only one explicit path in each section.
	unset ADA_INCLUDE_PATH ADA_OBJECT_PATH

	GCC_BRANCH_VER=${SLOT}
	GCC_CONFIG_VER=${GCC_ARCHIVE_VER}

	# Capture -march, -mcpu, -mtune and -mfpu options to do some initial configuration and optionally pass to build later.
	MARCH="${MARCH:-$(printf -- "${CFLAGS}" | sed -rne 's/.*-march="?([-_[:alnum:]]+).*/\1/p')}"
	MCPU="${MCPU:-$(printf -- "${CFLAGS}" | sed -rne 's/.*-mcpu="?([-_[:alnum:]]+).*/\1/p')}"
	MTUNE="${MTUNE:-$(printf -- "${CFLAGS}" | sed -rne 's/.*-mtune="?([-_[:alnum:]]+).*/\1/p')}"
	MFPU="${MFPU:-$(printf -- "${CFLAGS}" | sed -rne 's/.*-mfpu="?([-_[:alnum:]]+).*/\1/p')}"

	# Print captured flags.
	echo
	einfo "CFLAGS:          ${CFLAGS}"
	einfo "MARCH:           ${MARCH}"
	einfo "MCPU:            ${MCPU}"
	einfo "MTUNE:           ${MTUNE}"
	einfo "MFPU:            ${MFPU}"
	echo

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

	# TODO
	: ${TARGET_ABI:=${ABI}}
	: ${TARGET_MULTILIB_ABIS:=${MULTILIB_ABIS}}
	: ${TARGET_DEFAULT_ABI:=${DEFAULT_ABI}}

	# Set PATH for PREFIX, LIB, INCLUDE, BIN, DATA and STDCXX_INC.
	export PREFIX=/usr
	LIBPATH=${PREFIX}/lib/gcc/${CTARGET}/${GCC_CONFIG_VER}
	INCLUDEPATH=${LIBPATH}/include

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
	BOOT_CFLAGS="${BOOT_CFLAGS:--O2 -pipe $(get_abi_CFLAGS ${TARGET_DEFAULT_ABI})}"

	# BUILD_CONFIG is used for bringing additional customisation into the build.
	if use bootstrap && ! is_crosscompile || ! tc-is-cross-compiler; then
		# equivalent of adding -fsanitize=address to BOOT_CFLAGS
		use asan && BUILD_CONFIG="${BUILD_CONFIG:+${BUILD_CONFIG} }bootstrap-asan"
		# equivalent of adding -fcf-protection to BOOT_CFLAGS
		use cet && BUILD_CONFIG="${BUILD_CONFIG:+${BUILD_CONFIG} }bootstrap-cet"
		# 'bootstrap-debug' verifies that gcc generates the same executable code,
		# whether or not it is asked to emit debug info and is enabled by default.
		# 'bootstrap-debug-big' saves internal compiler dumps during stage2 and stage3
		# and compares them as well, at greater cost in terms of disk space.
		use debug && BUILD_CONFIG="${BUILD_CONFIG:+${BUILD_CONFIG} }bootstrap-debug-big"
		# equivalent of adding -flto to BOOT_CFLAGS
		use lto && BUILD_CONFIG="${BUILD_CONFIG:+${BUILD_CONFIG} }bootstrap-lto"
		# equivalent of adding -fsanitize=undefined to BOOT_CFLAGS
		use ubsan && BUILD_CONFIG="${BUILD_CONFIG:+${BUILD_CONFIG} }bootstrap-ubsan"
	fi

	# BUILD_CONFIG finished - export.
	export BUILD_CONFIG

	# GCC_TARGET is used for setting the make target.
	if use bootstrap && ! is_crosscompile || ! tc-is-cross-compiler; then
		# either regular bootstrap or profiled bootstrap
		use pgo && GCC_TARGET="profiledbootstrap" || GCC_TARGET="bootstrap"
	else
		# USE=-bootstrap , thus --disable-bootstrap will be passed in configure
		GCC_TARGET="all"
	fi

	# GCC_TARGET finished - export.
	export GCC_TARGET

	# TARGET_LIBC setup ...
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
		x86_64-*-mingw*)
			TARGET_LIBC=mingw64-runtime;;
		*-w64-mingw*)
			TARGET_LIBC=mingw64-runtime;;
		*-cygwin)
			TARGET_LIBC=cygwin;;
	esac

	# TARGET_LIBC finished - export.
	export TARGET_LIBC

	if use bpf; then
		GCC_BPF_TARGET="bpf-unknown-none"

		PREFIX_BPF=/usr
		LIBPATH_BPF=${PREFIX_BPF}/lib/gcc/${GCC_BPF_TARGET}/${GCC_CONFIG_VER}
		INCLUDEPATH_BPF=${LIBPATH_BPF}/include
		BINPATH_BPF=${PREFIX_BPF}/${GCC_BPF_TARGET}/gcc-bin/${GCC_CONFIG_VER}
		DATAPATH_BPF=${PREFIX_BPF}/share/gcc-data/${GCC_BPF_TARGET}/${GCC_CONFIG_VER}
	fi

	if use nvptx; then
		GCC_NVPTX_TARGET="nvptx-none"

		PREFIX_NVPTX=/usr
		LIBPATH_NVPTX=${PREFIX_NVPTX}/lib/gcc/${GCC_NVPTX_TARGET}/${GCC_CONFIG_VER}
		INCLUDEPATH_NVPTX=${LIBPATH_NVPTX}/include
		BINPATH_NVPTX=${PREFIX_NVPTX}/${GCC_NVPTX_TARGET}/gcc-bin/${GCC_CONFIG_VER}
		DATAPATH_NVPTX=${PREFIX_NVPTX}/share/gcc-data/${GCC_NVPTX_TARGET}/${GCC_CONFIG_VER}
		STDCXX_INCDIR_NVPTX=${LIBPATH_NVPTX}/include/g++-v${GCC_BRANCH_VER}
	fi

	# Disable gcc info regeneration -- it ships with generated info pages already.
	# Our custom version/urls/etc... trigger it.
	# Gentoo Linux bug #464008
	export gcc_cv_prog_makeinfo_modern=n
}

src_unpack() {

	# unpack gcc sources
	unpack ${GCC_A} || die "failed to unpack gcc sources"

	# logic for unpacking any required Ada bootstrap compilers when existing compiler isn't Ada compatible.
	# TODO: this logic is currently hidden behind USE=ada, but it should be changed to a generic bootstrap tarball.
	if use ada && use bootstrap && ! use system-bootstrap && ! is_crosscompile; then
		# create gnatboot directory
		mkdir "${WORKDIR}"/gnatboot || die "Failed to create gnatboot directory"

		# change to the gnatboot directory
		cd "${WORKDIR}"/gnatboot || die "Failed to change to gnatboot directory"

		# extract the gnat bootstrap compiler and move it to GNATBOOT directory
		case $(tc-arch) in
			x86)
			die "GNAT_X86_BOOTSTRAP support not yet implemented"
			;;
			amd64)
			unpack ${GNAT_AMD64_BOOTSTRAP}.tar.xz || die "Failed to unpack AMD64 GNAT bootstrap compiler"
			;;
			arm)
			die "GNAT_ARM_BOOTSTRAP support not yet implemented"
			;;
			arm64)
			die "GNAT_ARM64_BOOTSTRAP support not yet implemented"
			;;
			ppc)
			die "GNAT_PPC_BOOTSTRAP support not yet implemented"
			;;
			ppc64)
			die "GNAT_PPC64_BOOTSTRAP support not yet implemented"
			;;
		esac
		# done
	fi
}

src_prepare() {

	# For some reason, when upgrading gcc, the gcc Makefile will install stuff
	# like crtbegin.o into a subdirectory based on the name of the currently-installed
	# gcc version, rather than *our* gcc version. Manually fix this:

	sed -i -e "s/^version :=.*/version := ${GCC_CONFIG_VER}/" "${S}"/libgcc/Makefile.in || die

	# make sure the pkg config files install into multilib dirs.
	# since we configure with just one --libdir, we can't use that (as gcc itself takes care of building multilibs).
	# Gentoo Linux bug #435728
	find "${S}" -name Makefile.in -exec sed -i '/^pkgconfigdir/s:=.*:=$(toolexeclibdir)/pkgconfig:' {} +

	# Fixup libtool to correctly generate .la files with portage
	elibtoolize --portage --shallow --no-uclibc

	# update configure files
	local f
	einfo "Fixing misc issues in configure files"
	for f in $(grep -l 'autoconf version 2.13' $(find "${S}" -name configure)) ; do
		ebegin "  Updating ${f/${S}\/} [LANG]"
		patch "${f}" "${FILESDIR}"/gcc-configure-LANG.patch >& "${T}"/configure-patch.log || eerror "Please file a bug about this"
		eend "$?"
	done

	# Prevent new texinfo from breaking old versions (see #198182, #464008)
	eapply "${FILESDIR}/gcc-configure-texinfo.patch" || die "patch fail"

	setup_multilib_osdirnames

	# Gentoo Linux patches
	einfo "Applying Gentoo Linux patches ..."
	for my_patch in ${GENTOO_PATCHES[*]} ; do
		eapply "${GENTOO_PATCHES_DIR}/${my_patch}"
	done

	# Cairn Linux patches
	einfo "Applying Cairn Linux patches ..."
	for my_patch in ${CAIRN_PATCHES[*]} ; do
		eapply "${CAIRN_PATCHES_DIR}/${my_patch}"
	done

	# Alpine Linux patches
	# most of these are musl compatibility fixes, so hide it behind elibc_musl || cross*-musl*
	if use elibc_musl || [[ ${CATEGORY} = cross-*-musl* ]]; then
		einfo "Applying Alpine Linux patches ..."
		for my_patch in ${ALPINE_PATCHES[*]} ; do
			eapply "${ALPINE_PATCHES_DIR}/${my_patch}"
		done
	fi

	local gcc_hard_flags=""

	# TODO: disable pie in STAGE1_LDFLAGS? Gentoo Linux #618908
	# This will allow us to build older gcc with a pie enabled modern gcc.

	# Enable FORTIFY_SOURCE by default
	if use fortify_source; then
		eapply "${GENTOO_PATCHES_DIR}/01_all_default-fortify-source.patch"
	fi

	# TODO
	if use dev_extra_warnings ; then
		eapply "${GENTOO_PATCHES_DIR}/02_all_default-warn-format-security.patch"
		eapply "${GENTOO_PATCHES_DIR}/03_all_default-warn-trampolines.patch"

		einfo "Additional warnings enabled by default, this may break some tests and compilations with -Werror."
	fi

	# Enable BIND_NOW by default
	if use bind_now; then
		eapply "${CAIRN_PATCHES_DIR}/01_all_ENABLE_DEFAULT_BIND_NOW-z-now.patch"
		gcc_hard_flags+=" -DENABLE_DEFAULT_BIND_NOW "
	fi

	# Enable Stack Clash Protection by default
	if use scp; then
		eapply "${CAIRN_PATCHES_DIR}/02_all_ENABLE_DEFAULT_SCP-fstack-clash-protection.patch"
		gcc_hard_flags+=" -DENABLE_DEFAULT_SCP "
	fi

	# TODO
	if use ssp && use hardened; then
		eapply "${CAIRN_PATCHES_DIR}/03_all_ENABLE_DEFAULT_SSP_ALL-fstack-protector-all.patch"
		gcc_hard_flags+=" -DENABLE_DEFAULT_SSP_ALL "
	fi

	# Enable CET by default
	if use cet; then
		eapply "${CAIRN_PATCHES_DIR}/04_all_ENABLE_DEFAULT_CET.patch"
		gcc_hard_flags+=" -DENABLE_DEFAULT_CET"
	fi

	# GCC stores it's CFLAGS in the Makefile - here we make those CFLAGS == ${gcc_hard_flags} so that they are applied in the build process.
	sed -e '/^ALL_CFLAGS/iHARD_CFLAGS = '  -e 's|^ALL_CFLAGS = |ALL_CFLAGS = $(HARD_CFLAGS) |' -i "${S}"/gcc/Makefile.in || die "failed to write HARD_CFLAGS to gcc Makefile"
	sed -e '/^ALL_CXXFLAGS/iHARD_CFLAGS = '  -e 's|^ALL_CXXFLAGS = |ALL_CXXFLAGS = $(HARD_CFLAGS) |' -i "${S}"/gcc/Makefile.in || die "failed to write HARD_CXXFLAGS to gcc Makefile"

	# write HARD_CFLAGS back to the gcc Makefile.
	sed -i -e "/^HARD_CFLAGS = /s|=|= ${gcc_hard_flags} |" "${S}"/gcc/Makefile.in || die "failed to write CFLAGS to gcc Makefile"

	# apply any user patches
	eapply_user

	einfo "Touching generated files ..."
	./contrib/gcc_update --touch
}

src_configure() {

	local conf_gcc

# BRANDING:

	conf_gcc+=(
		--with-bugurl="http://bugs.cairnlinux.org"
		--with-pkgversion="${GCC_BRANDING}"
	)

# PATHS
	conf_gcc+=(
		--prefix=${PREFIX}
		--bindir=${BINPATH}
		--includedir=${INCLUDEPATH}
		--datadir=${DATAPATH}
		--mandir=${DATAPATH}/man
		--infodir=${DATAPATH}/info
		--with-gxx-include-dir=${STDCXX_INCDIR}
		# Stick the python scripts in their own slotted directory (Gentoo Linux bug #279252)
		--with-python-dir=${DATAPATH/$PREFIX/}/python
	)

	conf_gcc+=(
		--enable-obsolete
		--disable-werror
		--enable-secureplt
		--with-system-zlib
		--without-included-gettext
		--disable-libunwind-exceptions

		# Allow gcc to search for clock funcs in the main c library.
		# If it can't find them, then tough cookies, we aren't going to link in -lrt to all c++ programs.
		# Gentoo Linux bug #411681
		$(use_enable cxx libstdcxx-time)
	)

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
		conf_gcc+=( --enable-checking=release )
	elif use checking_yes; then
		conf_gcc+=( --enable-checking=yes )
	elif use checking_all; then
		conf_gcc+=( --enable-checking=all )
	else
		conf_gcc+=( --enable-checking=no )
	fi

# LANG
	# C/C++ used for stage1 compiler
	local GCC_LANG="c,c++"

	if use objc; then
		GCC_LANG+=",objc"
		use objc-gc && conf_gcc+=( --enable-objc-gc )
		use objc++ && GCC_LANG+=",obj-c++"
	fi

	use fortran && GCC_LANG+=",fortran"

	use go && GCC_LANG+=",go"

	# oh boy...
	if use ada; then
		GCC_LANG+=",ada"
		# TODO: move this to pkg_setup
		#
		# Straight from the manual...
		#
		# In order to build GNAT, the Ada compiler, you need a working GNAT compiler (GCC version 4.7 or later).
		# This includes GNAT tools such as gnatmake and gnatlink, since the Ada front end is written in Ada and uses some GNAT-specific extensions.
		#
		# In order to build a cross compiler, it is strongly recommended to install the new compiler as native first, and then use it to build the cross compiler.
		# Other native compiler versions may work but this is not guaranteed and will typically fail with hard to understand compilation errors during the build.
		#
		# Similarly, it is strongly recommended to use an older version of GNAT to build GNAT.
		# More recent versions of GNAT than the version built are not guaranteed to work and will often fail during the build with compilation errors.
		# Note that configure does not test whether the GNAT installation works and has a sufficiently recent version; if too old a GNAT version is installed and --enable-languages=ada is used, the build will fail.
		if use bootstrap && ! use system-bootstrap && ! is_crosscompile; then
			export GNATBOOT="${WORKDIR}"/gnatboot/usr
			PATH="${GNATBOOT}"/bin:${PATH}
			conf_gcc+=(
			    CC="${GNATBOOT}"/bin/gcc
			    CXX="${GNATBOOT}"/bin/g++
			    CPP="${GNATBOOT}"/bin/cpp
			    AS=as
			    LD=ld
			)
			einfo "Using Ada GNAT bootstrap compiler..."
		fi
		export PATH
		einfo "PATH = ${PATH}"
	fi

	use d && GCC_LANG+=",d"

	use jit && ! is_crosscompile && GCC_LANG+=",jit"

	if use lto; then
		GCC_LANG+=",lto"
	fi

	# and now add the GCC_LANG array to conf_gcc
	conf_gcc+=(
		--enable-languages=${GCC_LANG}
		--disable-libgcj
	)

# HOST/BUILD/TARGET:
	conf_gcc+=( --host=${CHOST} )

	# Straight from the manual:
	# GCC has logic to correctly determine the correct value for --target on nearly all native systems.
	# Therefore, we highly recommend you not provide a configure target when configuring a nativecompiler.
	if is_crosscompile || tc-is-cross-compiler; then
		conf_gcc+=( --target=${CTARGET} )
	fi

	# TODO: is_canadian_cross ?

	# Pass CBUILD if one exists
	if [[ -n ${CBUILD} ]]; then
		conf_gcc+=( --build=${CBUILD} )
	fi

# BOOTSTRAP NATIVE:
	if ! is_crosscompile; then
		$(use_enable bootstrap)
		$(use_enable openmp libgomp)
		tc-is-static-only && conf_gcc+=( --disable-shared ) || gcc_conf+=( --enable-shared )

		# CHOST specific options
		case ${CHOST} in
		mingw*|*-mingw*)
			# mingw requires win32 threads
			conf_gcc+=( --enable-threads=win32 )
			;;
		*)
			# default to posix threads for all other CHOST
			conf_gcc+=( --enable-threads=posix )
			;;
		esac
# BOOTSTRAP CROSS-COMPILER:
	elif is_crosscompile; then
		# Enable build warnings by default with cross-compilers when system paths are included (e.g. via -I flags).
		conf_gcc+=( --enable-poison-system-directories )

		# three stage bootstrapping doesnt quite work when you cant run the resulting binaries natively!
		conf_gcc+=( --disable-bootstrap )

		# Force disable for is_crosscompile as the configure script can be dumb - Gentoo Linux bug #359855
		conf_gcc+=( --disable-libgomp )

		case ${TARGET_LIBC} in
			dietlibc*)
				conf_gcc+=( --disable-libstdcxx-time )
				;;
			uclibc*)
				# Enable shared library support only on targets that support it: Gentoo Linux bug #291870
				if ! echo '#include <features.h>' |  $(tc-getCPP ${CTARGET}) -E -dD - 2>/dev/null |  grep -q __HAVE_SHARED__
				then
					conf_gcc+=( --disable-shared )
				fi
				;;
			avr*)
				conf_gcc+=( --disable-__cxa_atexit --enable-shared --disable-threads )
				;;
			x86_64-*mingw*|*-w64-mingw*)
				conf_gcc+=( --enable-shared --disable-threads)
				;;
		esac

		if [[ -n ${TARGET_LIBC} ]]; then
			# libc not yet installed
			if ! has_version ${CATEGORY}/${TARGET_LIBC}; then
				conf_gcc+=(
					--disable-shared
					# requires libc
					--disable-libatomic
					# libquadmath requires libc (Gentoo Linux #734820)
					--disable-libquadmath
					--disable-threads
					--without-headers
					--disable-libstdcxx
				)

				# By default gcc looks at glibc's headers to detect long-double support.
				# This does not work for --disable-headers mode.
				# >=glibc-2.4 is good enough for float128.
				# This option appeared in gcc-4.2.
				# Gentoo Linux bug # 738248

				if [[ ${TARGET_LIBC} == glibc ]]; then
					conf_gcc+=( --with-long-double-128 )
				fi
			# only libc headers are installed
			elif has_version "${CATEGORY}/${TARGET_LIBC}[headers-only]"; then
				conf_gcc+=(
					--disable-shared
					--disable-libatomic
					--with-sysroot=${PREFIX}/${CTARGET}
					--disable-libstdcxx
				)
			else
				# libc is installed
				conf_gcc+=(
					--with-sysroot=${PREFIX}/${CTARGET}
					--enable-libstdcxx-time
				)
			fi
		fi
	fi

# LIBC:
	# __cxa_atexit is "essential for fully standards-compliant handling of destructors", but apparently requires glibc.
	case ${CTARGET} in
	*-uclibc*)
		if use nptl ; then
			conf_gcc+=(
				--disable-__cxa_atexit
				$(use_enable nptl tls)
			)
		fi
		;;
	*-elf|*-eabi)
		conf_gcc+=( --with-newlib )
		;;
	*-musl*)
		conf_gcc+=( --enable-__cxa_atexit )
		;;
	*-gnu*)
		conf_gcc+=(
			--enable-__cxa_atexit
			--enable-clocale=gnu
		)
		;;
	*-freebsd*)
		conf_gcc+=( --enable-__cxa_atexit )
		;;
	*-solaris*)
		conf_gcc+=( --enable-__cxa_atexit )
		;;
	esac

# ARCH:
	if use multilib; then
		conf_gcc+=( --enable-multilib )
	else
		# Fun times: if we are building for a target that has multiple
		# possible ABI formats, and the user has told us to pick one
		# that isn't the default, then not specifying it via the list
		# below will break that on us.
		conf_gcc+=( --disable-multilib )
	fi

	$(use_enable multiarch)

	# translate our notion of multilibs into gcc's
	local abi list
	for abi in $(get_all_abis TARGET) ; do
		local l=$(gcc-abi-map ${abi})
		[[ -n ${l} ]] && list+=",${l}"
	done
	if [[ -n ${list} ]] ; then
		case ${CTARGET} in
			x86_64*)
				conf_gcc+=( --with-multilib-list=${list:1} )
			;;
		esac
	fi

	if use custom-cflags; then
		conf_gcc+=(
			--with-arch=${MARCH}
			--with-cpu=${MCPU}
			--with-tune=${MTUNE}
			--with-fpu=${MFPU}
		)
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
			if (srcdir="${S}"/gcc target=${CTARGET} with_arch=${arm_arch};
				. "${srcdir}"/config.gcc) &>/dev/null
			then
				conf_gcc+=( --with-arch=${arm_arch} )
			fi

			# Make default mode thumb for microcontroller classes
			# Gentoo Linux bug #418209
			[[ ${arm_arch} == *-m ]] && conf_gcc+=( --with-mode=thumb )

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
			conf_gcc+=( --with-float=$float )

			if [ -z "${MFPU}" ] && [ -n "${default_fpu}" ]; then
				conf_gcc+=( --with-fpu=${default_fpu} )
			fi

		;;
		mips)
			# Add --with-abi flags to set default ABI
			conf_gcc+=( --with-abi=$(gcc-abi-map ${TARGET_DEFAULT_ABI}) )
			;;
		amd64)
			# drop the older/ABI checks once this get's merged into some version of gcc upstream
			conf_gcc+=( --with-abi=$(gcc-abi-map ${TARGET_DEFAULT_ABI}) )
			;;
		x86)
			# Default arch for x86 is normally i386, lets give it a bump since glibc will do so based on CTARGET anyways
			conf_gcc+=( --with-arch=${CTARGET%%-*} )
			;;
		hppa)
			# Enable sjlj exceptions for backward compatibility on hppa
			[[ ${GCCMAJOR} == "3" ]] && conf_gcc+=( --enable-sjlj-exceptions )
			;;
		ppc)
			# Set up defaults based on current CFLAGS
			is-flagq -mfloat-gprs=double && conf_gcc+=( --enable-e500-double )
			[[ ${CTARGET//_/-} == *-e500v2-* ]] && conf_gcc+=( --enable-e500-double )
			;;
		ppc64)
			# On ppc64 big endian target gcc assumes elfv1 by default,
			# and elfv2 on little endian
			# but musl does not support elfv1 at all on any endian ppc64
			# see https://git.musl-libc.org/cgit/musl/tree/INSTALL
			# https://bugs.gentoo.org/704784
			# https://gcc.gnu.org/PR93157
			[[ ${CTARGET} == powerpc64-*-musl ]] && conf_gcc+=( --with-abi=elfv2 )
			;;
		riscv)
			# Add --with-abi flags to set default ABI
			conf_gcc+=( --with-abi=$(gcc-abi-map ${TARGET_DEFAULT_ABI}) )
			;;
	esac

	# If the target can do biarch (-m32/-m64), enable it.
	# Overhead should be small, and should simplify building of 64bit kernels in a 32bit userland by not needing kgcc64.
	# Gentoo Linux bug #349405
	case $(tc-arch) in
		ppc|ppc64)
			conf_gcc+=( --enable-targets=all )
			;;
		sparc)
			conf_gcc+=( --enable-targets=all )
			;;
		amd64|x86)
			conf_gcc+=( --enable-targets=all )
			;;
	esac

# FEATURES:
	# can this be shit canned? is solaris only, and i have better things to do with my time than support that
	use libssp || export gcc_cv_libc_provides_ssp=yes
	if use libssp; then
		conf_gcc+=( --enable-libssp )
	fi

	$(usex ada "--disable-libada" "")
	$(use_enable cet)
	$(use_enable fixed-point)
	$(usex graphite "--with-isl --disable-isl-version-check" "--without-isl")
	$(use_enable jit host-shared)
	$(use_enable lto)
	$(use_enable nls)
	$(use_enable pie default-pie)
	$(use_enable quad-math libquadmath)
	$(use_enable sanitize libsanitizer)
	$(use_enable ssp default-ssp)
	$(use_enable systemtap)
	$(use_enable valgrind)
	$(use_enable valgrind valgrind-annotations)
	$(use_enable vtv vtable-verify)
	$(use_enable vtv libvtv)
	$(use_with zstd)

	# === END FEATURE / LIBRARY CONFIGURATION ===

	# Pass any local EXTRA_ECONF from /etc/portage/env to ./configure.
	conf_gcc+=( "$@" ${EXTRA_ECONF} )

	# Pass BUILD_CONFIG to ./configure.
	conf_gcc+=( --with-build-config="${BUILD_CONFIG}" )

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
	einfo "Configuring GCC with: ${conf_gcc[@]//--/\n\t--}"
	echo

	# todo: force use of bash here? old gcc versions do not detect bash and re-exec itself.

	# finally run ./configure!
	../gcc-${GCC_ARCHIVE_VER}/configure "${conf_gcc[@]}" || die "failed to run configure"

	if use bpf; then

		# setup build directory
		mkdir "${WORKDIR}"/build-bpf || die "failed to create bpf build directory"

		# cd to build directory
		cd "${WORKDIR}"/build-bpf || die "failed to cd to bpf build directory"

		bpf_target_tools=(
			AR_FOR_TARGET=${TARGET}-ar
			AS_FOR_TARGET=${TARGET}-as
			LD_FOR_TARGET=${TARGET}-ld
			NM_FOR_TARGET=${TARGET}-nm
			OBJDUMP_FOR_TARGET=${TARGET}-objdump
			RANLIB_FOR_TARGET=${TARGET}-ranlib
			READELF_FOR_TARGET=${TARGET}-readelf
			STRIP_FOR_TARGET=${TARGET}-strip
		)

		conf_bpf=(
			--with-bugurl="http://bugs.cairnlinux.org"
			--with-pkgversion="${GCC_BRANDING}"

			--target=bpf
			--prefix=${PREFIX_BPF}
			--bindir=${BINPATH_BPF}
			--includedir=${INCLUDEPATH_BPF}
			--datadir=${DATAPATH_BPF}
			--mandir=${DATAPATH_BPF}/man
			--infodir=${DATAPATH_BPF}/info

			--enable-languages=c
			--with-system-zlib
			--without-included-gettext
			--disable-werror

			$(usex lto "--enable-lto" "--disable-lto" )
			$(usex quad-math "--enable-libquadmath" "--disable-libquadmath" )

			${bpf_target_tools[@]}
		)

		# TODO

		../gcc-${GCC_ARCHIVE_VER}/configure "${conf_bpf[@]}" || die "failed to configure gcc-bpf"
	fi

	if use nvptx; then

                # setup build directory
                mkdir "${WORKDIR}"/build-nvptx || die "failed to create nvptx build directory"

                # cd to build directory
                cd "${WORKDIR}"/build-nvptx || die "failed to cd to nvptx build directory"

		conf_nvptx=(
			--with-bugurl="http://bugs.cairnlinux.org"
			--with-pkgversion="${GCC_BRANDING}"

			--target=${GCC_NVPTX_TARGET}
			--prefix=${PREFIX_NVPTX}
			--bindir=${BINPATH_NVPTX}
			--includedir=${INCLUDEPATH_NVPTX}
			--datadir=${DATAPATH_NVPTX}
			--mandir=${DATAPATH_NVPTX}/man
			--infodir=${DATAPATH_NVPTX}/info
			--with-gxx-include-dir=${STDCXX_INCDIR_NVPTX}
		)

                # TODO

		../gcc-${GCC_ARCHIVE_VER}/configure "${conf_nvptx}" || die "failed to configure gcc-nvptx"
	fi

	is_crosscompile && gcc_conf_cross_post
}

gcc_conf_cross_post() {
	if use arm ; then
		sed -i "s/none-/${CHOST%%-*}-/g" "${WORKDIR}"/build/Makefile || die
	fi
}

src_compile() {

	cd "${WORKDIR}"/build || die "failed to cd to build directory"

	touch "${S}"/gcc/c-gperf.h

	# Unset ABI
	# leftover from Funtoo - needed?
	unset ABI

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
		emake -C "${WORKDIR}"/build/gcc gnatlib-shared
		# Building gnat toold
		emake -C "${WORKDIR}"/build/gcc gnattools
	fi

	# Optionally build some docs
	if ! is_crosscompile && use cxx && use doc; then
		if type -p doxygen > /dev/null ; then
			emake -C "${WORKDIR}"/build/"${CTARGET}"/libstdc++-v3/doc doc-man-doxygen

			# Clean bogus manpages
			# Gentoo Linux bug #113902
			find -name '*_build_*' -delete
			# Blow away generated directory references.  Newer versions of gcc
			# have gotten better at this, but not perfect.  This is easier than
			# backporting all of the various doxygen patches.  #486754
			find -name '*_.3' -exec grep -l ' Directory Reference ' {} + | xargs rm -f
		else
			ewarn "Skipping libstdc++ manpage generation since you don't have doxygen installed"
		fi
	fi

	# WIP
	if use bpf; then
		cd "${WORKDIR}"/build-bpf || die "failed to cd to build-bpf directory"

		touch "${S}"/gcc/c-gperf.h

		einfo "Compiling ${PN} (${GCC_BPF_TARGET})..."

		emake -C "${WORKDIR}"/build-bpf \
			STAGE1_CFLAGS="${STAGE1_CFLAGS}" \
			BOOT_CFLAGS="${BOOT_CFLAGS}" \
			LIBPATH="${LIBPATH}" \
			all || die "TODO"
	fi
}

src_test() {
	cd "${WORKDIR}/build"
	unset ABI
	local tests_failed=0
	if is_crosscompile || tc-is-cross-compiler; then
		ewarn "Running tests on simulator for cross-compiler not yet supported by this ebuild."
	else
		( ulimit -s 65536 && ${MAKE:-make} ${MAKEOPTS} LIBPATH="${ED%/}/${LIBPATH}" -k check RUNTESTFLAGS="-v -v -v" 2>&1 | tee "${T}"/make-check-log ) || tests_failed=1
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
		mdir=$($(get_make_var GCC_FOR_TARGET) $(get_abi_CFLAGS ${abi}) --print-multi-directory)
		ldpath=${LIBPATH}
		[[ ${mdir} != "." ]] && ldpath+="/${mdir}"
		ldpaths="${ldpath}${ldpaths:+:${ldpaths}}"

		mosdir=$($(get_make_var GCC_FOR_TARGET) $(get_abi_CFLAGS ${abi}) -print-multi-os-directory)
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

create_revdep_rebuild_entry() {
	local revdep_rebuild_base="/etc/revdep-rebuild/05cross-${CTARGET}-${GCC_CONFIG_VER}"
	local revdep_rebuild_file="${ED}${revdep_rebuild_base}"

	is_crosscompile || return 0

	dodir /etc/revdep-rebuild
	cat <<-EOF > "${revdep_rebuild_file}"
	# Generated by ${CATEGORY}/${PF}
	# Ignore libraries built for ${CTARGET}, https://bugs.gentoo.org/692844.
	SEARCH_DIRS_MASK="${LIBPATH}"
	EOF
}

# Move around the libs to the right location.  For some reason,
# when installing gcc, it dumps internal libraries into /usr/lib
# instead of the private gcc lib path
gcc_movelibs() {

	# For non-target libs which are for CHOST and not CTARGET, we want to
	# move them to the compiler-specific CHOST internal dir.  This is stuff
	# that you want to link against when building tools rather than building
	# code to run on the target.
	if tc_version_is_at_least 5 && is_crosscompile; then
		dodir "${HOSTLIBPATH#${EPREFIX}}"
		mv "${ED}"/usr/$(get_libdir)/libcc1* "${D}${HOSTLIBPATH}" || die
	fi

	# libgccjit gets installed to /usr/lib, not /usr/$(get_libdir), probably due to a bug in gcc build system.
	if use jit ; then
		dodir "${LIBPATH#${EPREFIX}}"
		mv "${ED}"/usr/lib/libgccjit* "${D}${LIBPATH}" || die
	fi

	# For all the libs that are built for CTARGET, move them into the
	# compiler-specific CTARGET internal dir.
	local x multiarg removedirs=""
	for multiarg in $($(get_make_var GCC_FOR_TARGET) -print-multi-lib) ; do
		multiarg=${multiarg#*;}
		multiarg=${multiarg//@/ -}

		local OS_MULTIDIR=$($(get_make_var GCC_FOR_TARGET) ${multiarg} --print-multi-os-directory)
		local MULTIDIR=$($(get_make_var GCC_FOR_TARGET) ${multiarg} --print-multi-directory)
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

# make sure the libtool archives have libdir set to where they actually
# -are-, and not where they -used- to be.  also, any dependencies we have
# on our own .la files need to be updated.
fix_libtool_libdir_paths() {
	local libpath="$1"

	pushd "${D}" >/dev/null

	pushd "./${libpath}" >/dev/null
	local dir="${PWD#${D%/}}"
	local allarchives=$(echo *.la)
	allarchives="\(${allarchives// /\\|}\)"
	popd >/dev/null

	# The libdir might not have any .la files. #548782
	find "./${dir}" -maxdepth 1 -name '*.la' -exec sed -i -e "/^libdir=/s:=.*:='${dir}':" {} + || die
	# Would be nice to combine these, but -maxdepth can not be specified
	# on sub-expressions.
	find "./${PREFIX}"/lib* -maxdepth 3 -name '*.la' -exec sed -i -e "/^dependency_libs=/s:/[^ ]*/${allarchives}:${libpath}/\1:g" {} + || die
	find "./${dir}/" -maxdepth 1 -name '*.la' -exec sed -i -e "/^dependency_libs=/s:/[^ ]*/${allarchives}:${libpath}/\1:g" {} + || die

	popd >/dev/null
}

src_install() {

# PRE-MAKE INSTALL SECTION:

	# Change to the build directory
	cd "${WORKDIR}"/build || die "failed to change to build directory"

	# Don't allow symlinks in private gcc include dir as this can break the build
	find gcc/include*/ -type l -delete

	# We remove the generated fixincludes, as they can cause things to break (ncurses, openssl, etc).
	# We do not prevent them from being built, as in the following commit which we revert:
	# https://sources.gentoo.org/cgi-bin/viewvc.cgi/gentoo-x86/eclass/toolchain.eclass?r1=1.647&r2=1.648
	# This is because bsd userland needs fixedincludes to build gcc, while linux does not.
	# Both can dispose of them afterwards.
	while read x ; do
		grep -q 'It has been auto-edited by fixincludes from' "${x}" \
			&& rm -f "${x}"
	done < <(find gcc/include*/ -name '*.h')

# MAKE INSTALL SECTION:

	# Do the 'make install' from the build directory
	S="${WORKDIR}"/build emake -j1 DESTDIR="${D}" install || die "make install failed"

# POST-MAKE INSTALL SECTION:

	# Move the libraries to the proper location
	gcc_movelibs

	# Basic sanity check
	if ! is_crosscompile ; then
		local EXEEXT
		eval $(grep ^EXEEXT= "${WORKDIR}"/build/gcc/config.log)
		[[ -r ${D}${BINPATH}/gcc${EXEEXT} ]] || die "gcc not found in ${ED}"
	fi

	dodir /etc/env.d/gcc
	create_gcc_env_entry
	create_revdep_rebuild_entry

# CLEAN-UP SECTION:

	# Punt some tools which are really only useful while building gcc
	find "${ED}" -name install-tools -prune -type d -exec rm -rf "{}" \;

	# This one comes with binutils
	find "${ED}" -name libiberty.a -delete

	# === LINK BINARIES

	dodir /usr/bin
	cd "${D}"${BINPATH}
	# Ugh: we really need to auto-detect this list.
	#      It's constantly out of date.
	for x in cpp gcc g++ c++ gcov g77 gcj gcjh gfortran gccgo gnat* ; do
		# For some reason, g77 gets made instead of ${CTARGET}-g77...
		# this should take care of that
		if [[ -f ${x} ]] ; then
			# In case they're hardlinks, clear out the target first
			# otherwise the mv below will complain.
			rm -f ${CTARGET}-${x}
			mv ${x} ${CTARGET}-${x}
		fi

		if [[ -f ${CTARGET}-${x} ]] ; then
			if ! is_crosscompile ; then
				ln -sf ${CTARGET}-${x} ${x}
				dosym ${BINPATH}/${CTARGET}-${x} /usr/bin/${x}-${GCC_CONFIG_VER}
			fi
			# Create versioned symlinks
			dosym ${BINPATH}/${CTARGET}-${x} /usr/bin/${CTARGET}-${x}-${GCC_CONFIG_VER}
		fi

		if [[ -f ${CTARGET}-${x}-${GCC_CONFIG_VER} ]] ; then
			rm -f ${CTARGET}-${x}-${GCC_CONFIG_VER}
			ln -sf ${CTARGET}-${x} ${CTARGET}-${x}-${GCC_CONFIG_VER}
		fi
	done

	# ?

	# When gcc builds a crosscompiler it does not install unprefixed tools.
	# When cross-building gcc does install native tools.
	if ! is_crosscompile; then
		# Rename the main go binaries as we don't want to clobber dev-lang/go
		# when gcc-config runs. #567806
		if tc_version_is_at_least 5 && use go ; then
			for x in go gofmt; do
				mv ${x} ${x}-${GCCMAJOR} || die
			done
		fi
	fi

	# === STRIPPING ? ===

	# As gcc installs object files built against bost ${CHOST} and ${CTARGET}
	# ideally we will need to strip them using different tools:
	# Using ${CHOST} tools:
	#  - "${D}${BINPATH}"
	#  - (for is_crosscompile) "${D}${HOSTLIBPATH}"
	#  - "${D}${PREFIX}/libexec/gcc/${CTARGET}/${GCC_CONFIG_VER}"
	# Using ${CTARGET} tools:
	#  - "${D}${LIBPATH}"
	# As dostrip does not specify host to override ${CHOST} tools just skip
	# non-native binary stripping.
	is_crosscompile && tc_supports_dostrip && dostrip -x "${LIBPATH}"

	cd "${S}"
	if is_crosscompile; then
		rm -rf "${ED}"/usr/share/{man,info}
		rm -rf "${D}"${DATAPATH}/{man,info}
	else
		local cxx_mandir=$(find "${WORKDIR}/build/${CTARGET}/libstdc++-v3" -name man)
		if [[ -d ${cxx_mandir} ]] ; then
			cp -r "${cxx_mandir}"/man? "${D}${DATAPATH}"/man/
		fi
	fi

	# portage regenerates 'dir' files on it's own: Gentoo Linux bug #672408
	# Drop 'dir' files to avoid collisions.
	if [[ -f "${D}${DATAPATH}"/info/dir ]]; then
		einfo "Deleting '${D}${DATAPATH}/info/dir'"
		rm "${D}${DATAPATH}"/info/dir || die
	fi

	# prune empty dirs left behind
	find "${ED}" -depth -type d -delete

	# libstdc++.la: Delete as it doesn't add anything useful: g++ itself
	# handles linkage correctly in the dynamic & static case.  It also just
	# causes us pain: any C++ progs/libs linking with libtool will gain a
	# reference to the full libstdc++.la file which is gcc version specific.
	# libstdc++fs.la: It doesn't link against anything useful.
	# libsupc++.la: This has no dependencies.
	# libcc1.la: There is no static library, only dynamic.
	# libcc1plugin.la: Same as above, and it's loaded via dlopen.
	# libcp1plugin.la: Same as above, and it's loaded via dlopen.
	# libgomp.la: gcc itself handles linkage (libgomp.spec).
	# libgomp-plugin-*.la: Same as above, and it's an internal plugin only
	# loaded via dlopen.
	# libgfortran.la: gfortran itself handles linkage correctly in the
	# dynamic & static case (libgfortran.spec). #573302
	# libgfortranbegin.la: Same as above, and it's an internal lib.
	# libmpx.la: gcc itself handles linkage correctly (libmpx.spec).
	# libmpxwrappers.la: See above.
	# libitm.la: gcc itself handles linkage correctly (libitm.spec).
	# libvtv.la: gcc itself handles linkage correctly.
	# lib*san.la: Sanitizer linkage is handled internally by gcc, and they
	# do not support static linking. #487550 #546700
	find "${D}${LIBPATH}" \
		'(' \
			-name libstdc++.la -o \
			-name libstdc++fs.la -o \
			-name libsupc++.la -o \
			-name libcc1.la -o \
			-name libcc1plugin.la -o \
			-name libcp1plugin.la -o \
			-name 'libgomp.la' -o \
			-name 'libgomp-plugin-*.la' -o \
			-name libgfortran.la -o \
			-name libgfortranbegin.la -o \
			-name libmpx.la -o \
			-name libmpxwrappers.la -o \
			-name libitm.la -o \
			-name libvtv.la -o \
			-name 'lib*san.la' \
		')' -type f -delete

	# Use gid of 0 because some stupid ports don't have
	# the group 'root' set to gid 0.  Send to /dev/null
	# for people who are testing as non-root.
	chown -R root:0 "${D}${LIBPATH}" 2>/dev/null

	# Installing gdb pretty-printers into gdb-specific location.
	local py gdbdir=/usr/share/gdb/auto-load${LIBPATH}
	pushd "${D}${LIBPATH}" >/dev/null
	for py in $(find . -name '*-gdb.py') ; do
		local multidir=${py%/*}
		insinto "${gdbdir}/${multidir}"
		sed -i "/^libdir =/s:=.*:= '${LIBPATH}/${multidir}':" "${py}" || die #348128
		doins "${py}" || die
		rm "${py}" || die
	done
	popd >/dev/null

	if use go; then
		# Don't scan .gox files for executable stacks - false positives
		export QA_EXECSTACK="usr/lib*/go/*/*.gox"
		export QA_WX_LOAD="usr/lib*/go/*/*.gox"
	fi

	# Disable RANDMMAP so PCH works. Gentoo Linux #301299
	if [[ ! is_crosscompile ]]; then
		pax-mark -r "${D}${PREFIX}/libexec/gcc/${CTARGET}/${GCC_CONFIG_VER}/cc1"
		pax-mark -r "${D}${PREFIX}/libexec/gcc/${CTARGET}/${GCC_CONFIG_VER}/cc1plus"
	fi
}

pkg_postinst() {

	do_gcc_config

	if [[ ! ${ROOT%/} && -f ${EPREFIX}/usr/share/eselect/modules/compiler-shadow.eselect ]] ; then
		eselect compiler-shadow update all
	fi

	if ! is_crosscompile && [[ ${PN} != "kgcc64" ]] ; then
		# gcc stopped installing .la files fixer in June 2020.
		# Cleaning can be removed in June 2022.
		rm -f "${EROOT%/}"/sbin/fix_libtool_files.sh
		rm -f "${EROOT%/}"/usr/sbin/fix_libtool_files.sh
		rm -f "${EROOT%/}"/usr/share/gcc-data/fixlafiles.awk
	fi
}

pkg_postrm() {

	do_gcc_config

	if [[ ! ${ROOT%/} && -f ${EPREFIX}/usr/share/eselect/modules/compiler-shadow.eselect ]] ; then
		eselect compiler-shadow clean all
	fi

	# clean up the cruft left behind by cross-compilers
	if is_crosscompile ; then
		if [[ -z $(ls "${EROOT%/}"/etc/env.d/gcc/${CTARGET}* 2>/dev/null) ]] ; then
			einfo "Removing last cross-compiler instance. Deleting dangling symlinks."
			rm -f "${EROOT%/}"/etc/env.d/gcc/config-${CTARGET}
			rm -f "${EROOT%/}"/etc/env.d/??gcc-${CTARGET}
			rm -f "${EROOT%/}"/usr/bin/${CTARGET}-{gcc,{g,c}++}{,32,64}
		fi
		return 0
	fi

	# gcc stopped installing .la files fixer in June 2020.
	# Cleaning can be removed in June 2022.
	rm -f "${EROOT%/}"/sbin/fix_libtool_files.sh
	rm -f "${EROOT%/}"/usr/share/gcc-data/fixlafiles.awk
}

do_gcc_config() {
	if ! should_we_gcc_config ; then
		gcc-config --use-old --force
		return 0
	fi

	local current_gcc_config target

	current_gcc_config=$(gcc-config -c ${CTARGET} 2>/dev/null)
	if [[ -n ${current_gcc_config} ]] ; then
		local current_specs use_specs
		# figure out which specs-specific config is active
		current_specs=$(gcc-config -S ${current_gcc_config} | awk '{print $3}')
		[[ -n ${current_specs} ]] && use_specs=-${current_specs}

		if [[ -n ${use_specs} ]] &&  [[ ! -e ${EROOT%/}/etc/env.d/gcc/${CTARGET}-${GCC_CONFIG_VER}${use_specs} ]]
		then
			ewarn "The currently selected specs-specific gcc config,"
			ewarn "${current_specs}, doesn't exist anymore. This is usually"
			ewarn "due to enabling/disabling hardened or switching to a version"
			ewarn "of gcc that doesnt create multiple specs files. The default"
			ewarn "config will be used, and the previous preference forgotten."
			use_specs=""
		fi

		target="${CTARGET}-${GCC_CONFIG_VER}${use_specs}"
	else
		# The curent target is invalid.  Attempt to switch to a valid one.
		# Blindly pick the latest version.  #529608
		# TODO: Should update gcc-config to accept `-l ${CTARGET}` rather than
		# doing a partial grep like this.
		target=$(gcc-config -l 2>/dev/null | grep " ${CTARGET}-[0-9]" | tail -1 | awk '{print $2}')
	fi

	gcc-config "${target}"
}

should_we_gcc_config() {
	# if the current config is invalid, we definitely want a new one
	# Note: due to bash quirkiness, the following must not be 1 line
	local curr_config
	curr_config=$(gcc-config -c ${CTARGET} 2>&1) || return 0

	# if the previously selected config has the same major.minor (branch) as
	# the version we are installing, then it will probably be uninstalled
	# for being in the same SLOT, make sure we run gcc-config.
	local curr_config_ver=$(gcc-config -S ${curr_config} | awk '{print $2}')

	local curr_branch_ver=$(ver_cut 1-2 ${curr_config_ver})

	if [[ ${curr_branch_ver} == ${GCC_BRANCH_VER} ]] ; then
		return 0
	else
		# if we're installing a genuinely different compiler version,
		# we should probably tell the user -how- to switch to the new
		# gcc version, since we're not going to do it for him/her.
		# We don't want to switch from say gcc-3.3 to gcc-3.4 right in
		# the middle of an emerge operation (like an 'emerge -e world'
		# which could install multiple gcc versions).
		# Only warn if we're installing a pkg as we might be called from
		# the pkg_{pre,post}rm steps.  #446830
		if [[ ${EBUILD_PHASE} == *"inst" ]] ; then
			einfo "The current gcc config appears valid, so it will not be"
			einfo "automatically switched for you.  If you would like to"
			einfo "switch to the newly installed gcc version, do the"
			einfo "following:"
			echo
			einfo "gcc-config ${CTARGET}-${GCC_CONFIG_VER}"
			einfo "source /etc/profile"
			echo
		fi
		return 1
	fi
}
