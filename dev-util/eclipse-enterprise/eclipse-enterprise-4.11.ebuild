# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit eutils

DESCRIPTION="Eclipse JEE"
HOMEPAGE="http://www.eclipse.org"
LICENSE="EPL-1.0"

SR="R"
RNAME="2019-03"
SRC_BASE="https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/${RNAME}/${SR}/eclipse-jee-${RNAME}-${SR}-linux-gtk"
SRC_URI="amd64? ( ${SRC_BASE}-x86_64.tar.gz&r=1 -> eclipse-jee-${RNAME}-${SR}-linux-gtk-x86_64-${PV}.tar.gz )"

SLOT="4.11"
KEYWORDS="amd64"

IUSE=""

RDEPEND="
	!dev-util/eclipse-sdk
	>=virtual/java-8
	x11-libs/gtk+:2"

S=${WORKDIR}/eclipse

src_install() {
	local dest=/opt/${PN}-${SLOT}

	insinto ${dest}
	doins -r features icon.xpm plugins artifacts.xml p2 eclipse.ini configuration dropins

	exeinto ${dest}
	doexe eclipse

	cp "${FILESDIR}"/eclipserc "${T}" || die
	cp "${FILESDIR}"/eclipse "${T}" || die
	sed "s@%SLOT%@${SLOT}@" -i "${T}"/eclipse{,rc} || die

	insinto /etc
	newins "${T}"/eclipserc eclipserc

	newbin "${T}"/eclipse eclipse
	make_desktop_entry "eclipse" "Eclipse Java Enterprise Edition" "${dest}/icon.xpm"
}
