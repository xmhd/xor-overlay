# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit eutils flag-o-matic gnuconfig libtool multilib toolchain-funcs

DESCRIPTION="Tools necessary to build programs"
HOMEPAGE="https://sourceware.org/binutils/"
LICENSE="GPL-3+"

SRC_URI=""

IUSE="default-gold doc +gold multitarget +nls +plugins static-libs test"

REQUIRED_USE="
    default-gold? ( gold )
"

RDEPEND="
	>=sys-devel/binutils-config-3
	sys-libs/zlib
"

DEPEND="${RDEPEND}"

BDEPEND="
	doc? ( sys-apps/texinfo )
	test? ( dev-util/dejagnu )
	nls? ( sys-devel/gettext )
	sys-devel/flex
	virtual/yacc
"

RESTRICT="!test? ( test )"

GENTOO_PATCHES_DIR="${FILESDIR}/gentoo-patches/${PV}/"

GENTOO_PATCHES=(
        # TODO
)

pkg_pretend() {

	# This check should probably go somewhere else, like pkg_pretend.
	if [[ ${CTARGET} == *-uclibc* ]] ; then
		if grep -qs 'linux-gnu' "${S}"/ltconfig ; then
			die "sorry, but this binutils doesn't yet support uClibc :("
		fi
	fi

}

pkg_setup() {

	# Setup some paths
	LIBPATH=/usr/$(get_libdir)/binutils/${CTARGET}/${PV}
	INCPATH=${LIBPATH}/include
	DATAPATH=/usr/share/binutils-data/${CTARGET}/${PV}
	if is_cross ; then
		TOOLPATH=/usr/${CHOST}/${CTARGET}
	else
		TOOLPATH=/usr/${CTARGET}
	fi
	BINPATH=${TOOLPATH}/binutils-bin/${PV}

    #
    # The cross-compile logic
    #
    export CTARGET=${CTARGET:-${CHOST}}
    if [[ ${CTARGET} == ${CHOST} ]] ; then
        if [[ ${CATEGORY} == cross-* ]] ; then
            export CTARGET=${CATEGORY#cross-}
        fi
    fi
}

src_unpack() {
    default
}

src_prepare() {

	# Make sure our explicit libdir paths don't get clobbered. #562460
	sed -i \
		-e 's:@bfdlibdir@:@libdir@:g' \
		-e 's:@bfdincludedir@:@includedir@:g' \
		{bfd,opcodes}/Makefile.in || die

	# Fix locale issues if possible #122216
	if [[ -e ${FILESDIR}/binutils-configure-LANG.patch ]] ; then
		einfo "Fixing misc issues in configure files"
		for f in $(find "${S}" -name configure -exec grep -l 'autoconf version 2.13' {} +) ; do
			ebegin "  Updating ${f/${S}\/}"
			patch "${f}" "${FILESDIR}"/binutils-configure-LANG.patch >& "${T}"/configure-patch.log || eerror "Please file a bug about this"
			eend $?
		done
	fi

	# Fix conflicts with newer glibc #272594
	if [[ -e libiberty/testsuite/test-demangle.c ]] ; then
		sed -i 's:\<getline\>:get_line:g' libiberty/testsuite/test-demangle.c
	fi

	# Apply things from PATCHES and user dirs
	eapply_user

	# Run misc portage update scripts
	gnuconfig_update
	elibtoolize --portage --no-uclibc
}