# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit gnome2-utils xdg

DESCRIPTION=""
HOMEPAGE="https://netbeans.apache.org"
LICENSE="Apache-2.0"

SLOT="0"

BDEPEND="
	app-arch/unzip
"

RDEPEND="
	virtual/jdk
"

RESTRICT="strip"

S="${WORKDIR}/${PN}-${PV}"

if [[ ${PV} != 9999 ]]; then
	SRC_URI="https://www-us.apache.org/dist/incubator/${PN}/incubating-netbeans/incubating-${PV}/incubating-netbeans-${PV}-bin.zip -> ${PN}-${PV}.zip"
	KEYWORDS="*"
fi

src_unpack() {
	default
	mv "${WORKDIR}"/netbeans* "${S}" || die "Failed to move/rename source dir"
}

src_install() {
	insinto "/opt/${PN}"
	doins -r *

	fperms 755 /opt/${PN}/bin/${PN}

	dosym ../../opt/${PN}/bin/${PN} /usr/bin/${PN}

	newicon "/opt/${PN}/nb/${PN}.png" "${PN}.png"
	make_desktop_entry "${PN}" "Netbeans" "${PN}" "Development;Programming;IDE;"
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_icon_cache_update
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_icon_cache_update
}
