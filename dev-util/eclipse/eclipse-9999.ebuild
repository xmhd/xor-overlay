# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit gnome2-utils xdg

DESCRIPTION="Eclipse IDE"
HOMEPAGE="http://www.eclipse.org"
LICENSE="EPL-1.0"

KEYWORDS="amd64"
SLOT="0"

BDEPEND="
        app-arch/tar
"

RDEPEND="
        !dev-util/eclipse-enterprise
        virtual/jdk
        x11-libs/gtk+:2
"

RESTRICT="strip"

S=${WORKDIR}/eclipse

SRC_URI_BASE="https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release"

if [[ ${PV} == 4.16 ]]; then
        SRC_URI="${SRC_URI_BASE}/2020-03/R/eclipse-java-2020-03-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-java-2020-06-R-linux-gtk-x86_64-${PV}.tar.gz"
elif [[ ${PV} == 4.15 ]]; then
        SRC_URI="${SRC_URI_BASE}/2020-03/R/eclipse-java-2020-03-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-java-2020-03-R-linux-gtk-x86_64-${PV}.tar.gz"
elif [[ ${PV} == 4.14 ]]; then
        SRC_URI="${SRC_URI_BASE}/2019-12/R/eclipse-java-2019-12-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-java-2019-12-R-linux-gtk-x86_64-${PV}.tar.gz"
fi

src_install() {

        insinto "/opt/${PN}"
        doins -r *

        fperms 755 /opt/${PN}/${PN}

        dosym ../../opt/${PN}/${PN} /usr/bin/${PN}

	cp "${FILESDIR}/eclipse.conf" "${T}"
	insinto "/etc"
	newins "${T}/eclipse.conf" "eclipse.conf"

	newicon "icon.xpm" "${PN}.png"
        make_desktop_entry "eclipse" "Eclipse" "${PN}" "Development;"
}

pkg_postinst() {
        xdg_pkg_postinst
        gnome2_icon_cache_update
}

pkg_postrm() {
        xdg_pkg_postrm
        gnome2_icon_cache_update
}
