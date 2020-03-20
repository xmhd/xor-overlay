# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

MINOR=8

DESCRIPTION="DTrace userspace"
HOMEPAGE="https://github.com/oracle/dtrace-utils"
SRC_URI="https://github.com/oracle/dtrace-utils/archive/${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="test +dtrace-headers"

DEPEND="
	${RDEPEND}
	virtual/os-headers
	sys-devel/bison
	sys-devel/flex
	dtrace-headers? ( sys-kernel/dtrace-sources[header-link] )"

RDEPEND="
	dev-libs/elfutils
	sys-libs/zlib
	dev-libs/libdtrace-ctf
"

src_unpack() {
	unpack ${A}
	mv ${WORKDIR}/dtrace-utils-${PN}-${PV}-${MINOR} ${WORKDIR}/${P}
	use test || rm -r ${WORKDIR}/${P}/test
}
