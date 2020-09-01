# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="CTF library"
HOMEPAGE="https://github.com/oracle/libdtrace-ctf"
SRC_URI="https://github.com/oracle/${PN}/archive/${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE=""

DEPEND="
	${RDEPEND}
	virtual/os-headers
"
RDEPEND="
	dev-libs/elfutils
	sys-libs/zlib
"

src_unpack() {
	unpack ${A}
	mv ${WORKDIR}/${PN}-${P} ${WORKDIR}/${P}
}
