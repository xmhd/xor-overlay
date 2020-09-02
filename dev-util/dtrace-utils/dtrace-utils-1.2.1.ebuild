# Distributed under the terms of the GNU General Public License v2

EAPI=7

HOMEPAGE="https://github.com/oracle/dtrace-utils"
DESCRIPTION="DTrace userspace utilities"

LICENSE="GPL-2"
KEYWORDS="x86 amd64"

SLOT="0"

IUSE="test"

RDEPEND="
    dev-libs/elfutils
    dev-libs/libdtrace-ctf
    sys-libs/zlib
"

DEPEND="
    sys-devel/bison
    sys-kernel/debian-sources[dtrace]
    sys-devel/flex
    virtual/os-headers
"

DTRACE_UTILS_VER="1.2.1"
DTRACE_UTILS_REV="1"
DTRACE_UTILS_ARCHIVE="${DTRACE_UTILS_VER}-${DTRACE_UTILS_REV}.tar.gz"

SRC_URI="https://github.com/oracle/dtrace-utils/archive/${DTRACE_UTILS_ARCHIVE}"


src_unpack() {

    unpack ${DTRACE_UTILS_ARCHIVE} && mv ${WORKDIR}/${PN}-${DTRACE_UTILS_VER}-${DTRACE_UTILS_REV} ${WORKDIR}/${PN}-${DTRACE_UTILS_VER} || die "failed to unpack archive"
}