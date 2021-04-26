# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic toolchain-funcs

HOMEPAGE="https://github.com/oracle/dtrace-utils"
DESCRIPTION="DTrace userspace utilities"

LICENSE="GPL-2"
KEYWORDS="x86 amd64"

SLOT="0"

IUSE="test"

DEPEND="
	sys-devel/bison
	sys-devel/flex
	virtual/os-headers
"

RDEPEND="
	dev-libs/elfutils
	dev-libs/libdtrace-ctf
	net-libs/libpcap
	sys-libs/zlib
"

DTRACE_UTILS_VER="1.2.1"
DTRACE_UTILS_REV="1"
DTRACE_UTILS_ARCHIVE="${DTRACE_UTILS_VER}-${DTRACE_UTILS_REV}.tar.gz"

SRC_URI="https://github.com/oracle/dtrace-utils/archive/${DTRACE_UTILS_ARCHIVE}"

src_unpack() {

	unpack ${DTRACE_UTILS_ARCHIVE} && mv "${WORKDIR}"/${PN}-${DTRACE_UTILS_VER}-${DTRACE_UTILS_REV} "${WORKDIR}"/${PN}-${DTRACE_UTILS_VER} || die "failed to unpack archive"

	if ! use test ; then
		rm -rf "${WORKDIR}"/${PN}-${PV}/test || die "failed to remove tests"
	fi
}

src_configure() {

	# work around gcc-10 defaulting to -fno-common
	if ver_test $(gcc-fullversion) -ge 10 ; then
		append-cflags -fcommon
	fi
}
