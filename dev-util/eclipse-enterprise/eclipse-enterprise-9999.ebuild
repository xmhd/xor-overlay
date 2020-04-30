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

SRC_URI_BASE="https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/${RNAME}/${SR}/eclipse-jee-${RNAME}-${SR}-linux-gtk"
MY_PN="eclipse"

if [[ ${PV} == 4.15 ]]; then
        SRC_URI="${SRC_URI_BASE}/2020-03/R/eclipse-jee-2020-03-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-jee-2020-03-R-linux-gtk-x86_64-${PV}.tar.gz"
        KEYWORDS="amd64"
elif [[ ${PV} == 4.14 ]]; then
        SRC_URI="${SRC_URI_BASE}/2019-12/R/eclipse-jee-2019-12-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-jee-2019-12-R-linux-gtk-x86_64-${PV}.tar.gz"
        KEYWORDS="amd64"
elif [[ ${PV} == 4.13 ]]; then
        SRC_URI="${SRC_URI_BASE}/2019-09/R/eclipse-jee-2019-09-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-jee-2019-09-R-linux-gtk-x86_64-${PV}.tar.gz"
        KEYWORDS="amd64"
elif [[ ${PV} == 4.12 ]]; then
        SRC_URI="${SRC_URI_BASE}/2019-06/R/eclipse-jee-2019-06-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-jee-2019-06-R-linux-gtk-x86_64-${PV}.tar.gz"
        KEYWORDS="amd64"
elif [[ ${PV} == 4.11 ]]; then
        SRC_URI="${SRC_URI_BASE}/2019-03/R/eclipse-jee-2019-03-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-jee-2019-03-R-linux-gtk-x86_64-${PV}.tar.gz"
        KEYWORDS="amd64"
elif [[ ${PV} == 4.10 ]]; then
	SRC_URI="${SRC_URI_BASE}/2018-12/R/eclipse-jee-2018-12-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-jee-2018-12-R-linux-gtk-x86_64-${PV}.tar.gz"
	KEYWORDS="amd64"
elif [[ ${PV} == 4.9.0 ]]; then
	SRC_URI="
		x86? ( "${SRC_URI_BASE}/2018-09/R/eclipse-jee-2018-09-R-linux-gtk.tar.gz&r=1 -> eclipse-jee-2018-09-R-linux-gtk-${PV}.tar.gz" )
		amd64? ( "${SRC_URI_BASE}/2018-09/R/eclipse-jee-2018-09-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-jee-2018-09-R-linux-gtk-x86_64-${PV}.tar.gz" )
	"
	KEYWORDS="x86 amd64"
elif [[ ${PV} == 4.8.0 ]]; then
        SRC_URI="
                x86? ( "${SRC_URI_BASE}/photon/R/eclipse-jee-photon-R-linux-gtk.tar.gz&r=1 -> eclipse-jee-photon-R-linux-gtk-${PV}.tar.gz" )
                amd64? ( "${SRC_URI_BASE}/photon/R/eclipse-jee-photon-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-jee-photon-R-linux-gtk-x86_64-${PV}.tar.gz" )
        "
	KEYWORDS="x86 amd64"
elif [[ ${PV} == 4.7.3 ]]; then
        SRC_URI="
                x86? ( "${SRC_URI_BASE}/oxygen/R/eclipse-jee-oxygen-R-linux-gtk.tar.gz&r=1 -> eclipse-jee-oxygen-R-linux-gtk-${PV}.tar.gz" )
                amd64? ( "${SRC_URI_BASE}/oxygen/R/eclipse-jee-oxygen-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-jee-oxygen-R-linux-gtk-x86_64-${PV}.tar.gz" )
        "
	KEYWORDS="x86 amd64"
elif [[ ${PV} == 4.6.3 ]]; then
        SRC_URI="
                x86? ( "${SRC_URI_BASE}/neon/R/eclipse-jee-neon-R-linux-gtk.tar.gz&r=1 -> eclipse-jee-neon-R-linux-gtk-${PV}.tar.gz" )
                amd64? ( "${SRC_URI_BASE}/neon/R/eclipse-jee-neon-R-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-jee-neon-R-linux-gtk-x86_64-${PV}.tar.gz" )
        "
	KEYWORDS="x86 amd64"
elif [[ ${PV} == 4.5.2 ]]; then
        SRC_URI="
                x86? ( "${SRC_URI_BASE}/mars/2/eclipse-jee-mars-2-linux-gtk.tar.gz&r=1 -> eclipse-jee-mars-2-linux-gtk-${PV}.tar.gz" )
                amd64? ( "${SRC_URI_BASE}/mars/2/eclipse-jee-mars-2-linux-gtk-x86_64.tar.gz&r=1 -> eclipse-jee-mars-2-linux-gtk-x86_64-${PV}.tar.gz" )
        "
	KEYWORDS="x86 amd64"
fi

pkg_pretend() {
        if has network-sandbox ${FEATURES}; then
                eerror
                eerror "Eclipse ebuild contains many SRC_URI links which spam the"
                eerror "network-sandbox log. The emerge will complete successfully,"
                eerror "however to hide this spam either use FEATURES=-network-sandbox"
                eerror "or use env + package.env to permanently disable network-sandbox"
                eerror "for this package"
                eerror
                eerror "see:"
                eerror"    https://wiki.gentoo.org/wiki//etc/portage/package.env"
                eerror
                die "network-sandbox is enabled, disable it to proceed";
        fi
}

src_install() {

        insinto "/opt/${MY_PN}"
        doins -r *

        fperms 755 /opt/${MY_PN}/${MY_PN}

        dosym ../../opt/${MY_PN}/${MY_PN} /usr/bin/${MY_PN}

	cp "${FILESDIR}/eclipse.conf" "${T}"
	insinto "/etc"
	newins "${T}/eclipse.conf" "eclipse.conf"

	newicon "icon.xpm" "${MY_PN}.png"
        make_desktop_entry "eclipse" "Eclipse Enterprise" "${MY_PN}" "Development;"
}

pkg_postinst() {
        xdg_pkg_postinst
        gnome2_icon_cache_update
}

pkg_postrm() {
        xdg_pkg_postrm
        gnome2_icon_cache_update
}
