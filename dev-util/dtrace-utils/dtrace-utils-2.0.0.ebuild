# Distributed under the terms of the GNU General Public License v2

EAPI=7

HOMEPAGE="https://github.com/oracle/dtrace-utils"
DESCRIPTION="DTrace userspace utilities"

LICENSE="GPL-2"
KEYWORDS="x86 amd64"

SLOT="0"

IUSE="dtrace-headers test"

RDEPEND="
    dev-libs/elfutils
    dev-libs/libdtrace-ctf
    sys-libs/zlib
"

DEPEND="
    sys-devel/bison
    dtrace-headers? ( sys-kernel/debian-sources[dtrace] )
    sys-devel/flex
    virtual/os-headers
"

DTRACE_UTILS_VER="2.0.0"
DTRACE_UTILS_REV="1.2"

SRC_URI="https://github.com/oracle/dtrace-utils/archive/${DTRACE_UTILS_VER}-${DTRACE_UTILS_REV}.tar.gz"

src_unpack() {

	unpack ${A}
	mv ${WORKDIR}/dtrace-utils-${PN}-${PV}-${MINOR} ${WORKDIR}/${P}
	use test || rm -r ${WORKDIR}/${P}/test

}