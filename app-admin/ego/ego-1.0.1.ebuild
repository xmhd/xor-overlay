# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit python-r1

DESCRIPTION="Funtoo's configuration tool: ego, epro."
HOMEPAGE="http://www.funtoo.org/Package:Ego"
SRC_URI="https://github.com/funtoo/ego/tarball/${PV} -> ${PN}-${PV}.tar.gz"

LICENSE="GPL-2"
KEYWORDS="~amd64"

SLOT="0"

IUSE=""

RDEPEND="
	$PYTHON_DEPS
"

src_unpack() {
	unpack ${A}
	mv "${WORKDIR}/funtoo-ego"-??????? "${S}" || die
}

src_install() {
	exeinto /usr/share/ego/modules
	doexe $S/modules/*
	insinto /usr/share/ego/modules-info
	doins $S/modules-info/*
	dobin $S/ego
	dosym ../share/ego/modules/profile.ego /usr/sbin/epro
	doman ego.1 epro.1
}
