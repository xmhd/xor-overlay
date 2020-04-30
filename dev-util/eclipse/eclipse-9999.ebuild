# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit gnome2-utils xdg

DESCRIPTION="Eclipse IDE"
HOMEPAGE="http://www.eclipse.org"
LICENSE="EPL-1.0"

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

if [[ ${PV} == 4.15 ]]; then
        SRC_URI="${SRC_URI_BASE}/2020-03/R/eclipse-java-2020-03-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-java-2020-03-R-linux-gtk-x86_64-${PV}.tar.gz"
        KEYWORDS="amd64"
elif [[ ${PV} == 4.14 ]]; then
        SRC_URI="${SRC_URI_BASE}/2019-12/R/eclipse-java-2019-12-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-java-2019-12-R-linux-gtk-x86_64-${PV}.tar.gz"
        KEYWORDS="amd64"
elif [[ ${PV} == 4.13 ]]; then
        SRC_URI="${SRC_URI_BASE}/2019-09/R/eclipse-java-2019-09-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-java-2019-09-R-linux-gtk-x86_64-${PV}.tar.gz"
        KEYWORDS="amd64"
elif [[ ${PV} == 4.12 ]]; then
        SRC_URI="${SRC_URI_BASE}/2019-06/R/eclipse-java-2019-06-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-java-2019-06-R-linux-gtk-x86_64-${PV}.tar.gz"
        KEYWORDS="amd64"
elif [[ ${PV} == 4.11 ]]; then
        SRC_URI="${SRC_URI_BASE}/2019-03/R/eclipse-java-2019-03-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-java-2019-03-R-linux-gtk-x86_64-${PV}.tar.gz"
        KEYWORDS="amd64"
elif [[ ${PV} == 4.10 ]]; then
	SRC_URI="${SRC_URI_BASE}/2018-12/R/eclipse-java-2018-12-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-java-2018-12-R-linux-gtk-x86_64-${PV}.tar.gz"
	KEYWORDS="amd64"
elif [[ ${PV} == 4.9.0 ]]; then
	SRC_URI="
		x86? ( "${SRC_URI_BASE}/2018-09/R/eclipse-java-2018-09-R-linux-gtk.tar.gz&r=1 -> eclipse-java-2018-09-R-linux-gtk-${PV}.tar.gz" )
		amd64? ( "${SRC_URI_BASE}/2018-09/R/eclipse-java-2018-09-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-java-2018-09-R-linux-gtk-x86_64-${PV}.tar.gz" )
	"
	KEYWORDS="x86 amd64"
elif [[ ${PV} == 4.8.0 ]]; then
        SRC_URI="
                x86? ( "${SRC_URI_BASE}/photon/R/eclipse-java-photon-R-linux-gtk.tar.gz&r=1 -> eclipse-java-photon-R-linux-gtk-${PV}.tar.gz" )
                amd64? ( "${SRC_URI_BASE}/photon/R/eclipse-java-photon-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-java-photon-R-linux-gtk-x86_64-${PV}.tar.gz" )
        "
	KEYWORDS="x86 amd64"
elif [[ ${PV} == 4.7.3 ]]; then
        SRC_URI="
                x86? ( "${SRC_URI_BASE}/oxygen/R/eclipse-java-oxygen-R-linux-gtk.tar.gz&r=1 -> eclipse-java-oxygen-R-linux-gtk-${PV}.tar.gz" )
                amd64? ( "${SRC_URI_BASE}/oxygen/R/eclipse-java-oxygen-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-java-oxygen-R-linux-gtk-x86_64-${PV}.tar.gz" )
        "
	KEYWORDS="x86 amd64"
elif [[ ${PV} == 4.6.3 ]]; then
        SRC_URI="
                x86? ( "${SRC_URI_BASE}/neon/R/eclipse-java-neon-R-linux-gtk.tar.gz&r=1 -> eclipse-java-neon-R-linux-gtk-${PV}.tar.gz" )
                amd64? ( "${SRC_URI_BASE}/neon/R/eclipse-java-neon-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-java-neon-R-linux-gtk-x86_64-${PV}.tar.gz" )
        "
	KEYWORDS="x86 amd64"
elif [[ ${PV} == 4.5.2 ]]; then
        SRC_URI="
                x86? ( "${SRC_URI_BASE}/mars/2/eclipse-java-mars-2-linux-gtk.tar.gz&r=1 -> eclipse-java-mars-2-linux-gtk-${PV}.tar.gz" )
                amd64? ( "${SRC_URI_BASE}/mars/2/eclipse-java-mars-2-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-java-mars-2-linux-gtk-x86_64-${PV}.tar.gz" )
        "
	KEYWORDS="x86 amd64"
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
