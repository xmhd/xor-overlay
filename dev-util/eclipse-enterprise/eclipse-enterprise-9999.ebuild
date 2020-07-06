# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit gnome2-utils xdg

DESCRIPTION="Eclipse JEE"
HOMEPAGE="http://www.eclipse.org"
LICENSE="EPL-1.0"

SLOT="0"

BDEPEND="
        app-arch/tar
"

RDEPEND="
        !dev-util/eclipse
        virtual/jdk
        x11-libs/gtk+:2
"

RESTRICT="strip"

S=${WORKDIR}/eclipse

SRC_URI_BASE="https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/"
MY_PN="eclipse"


if [[ ${PV} == 4.16 ]]; then
        SRC_URI="${SRC_URI_BASE}/2020-03/R/eclipse-jee-2020-06-R-incubation-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-jee-2020-03-R-incubation-linux-gtk-x86_64-${PV}.tar.gz"
elif [[ ${PV} == 4.15 ]]; then
        SRC_URI="${SRC_URI_BASE}/2020-03/R/eclipse-jee-2020-03-R-incubation-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-jee-2020-03-R-incubation-linux-gtk-x86_64-${PV}.tar.gz"
elif [[ ${PV} == 4.14 ]]; then
        SRC_URI="${SRC_URI_BASE}/2019-12/R/eclipse-jee-2019-12-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-jee-2019-12-R-linux-gtk-x86_64-${PV}.tar.gz"
fi

src_install() {

        insinto "/opt/${MY_PN}"
        doins -r *

        fperms 755 /opt/${MY_PN}/${MY_PN}

        dosym ../../opt/${MY_PN}/${MY_PN} /usr/bin/${MY_PN}

	cp "${FILESDIR}/eclipse.conf" "${T}"
	insinto "/etc"
	newins "${T}/eclipse.conf" "eclipse.conf"

	newicon "icon.xpm" "${MY_PN}.png"
        make_desktop_entry "eclipse" "Eclipse" "${MY_PN}" "Development;"
}

pkg_postinst() {
        xdg_pkg_postinst
        gnome2_icon_cache_update
}

pkg_postrm() {
        xdg_pkg_postrm
        gnome2_icon_cache_update
}
