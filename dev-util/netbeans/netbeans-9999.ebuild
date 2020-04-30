# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit gnome2-utils xdg

DESCRIPTION="Netbeans IDE by Apache, formerly by Sun"
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
	SRC_URI="https://archive.apache.org/dist/${PN}/${PN}/${PV}/netbeans-${PV}-bin.zip -> ${PN}-${PV}.zip"
	KEYWORDS="*"
fi

src_unpack() {
	default
	mv "${WORKDIR}"/netbeans* "${S}" || die "Failed to move/rename source dir"
}

src_prepare() {
	default

	# Disable sandbox while we make any necessary modications
        export SANDBOX_ON=0

        cd "${S}"

	# Set jdkhome, Netbeans _will not_ start without this being set.
        sed -i -e 's@#netbeans_jdkhome="/path/to/jdk"@netbeans_jdkhome="$JAVA_HOME"@' "etc/${PN}.conf"
}


src_install() {
	insinto "/opt/${PN}"
	doins -r *

	fperms 755 /opt/${PN}/bin/${PN}

	dosym ../../opt/${PN}/bin/${PN} /usr/bin/${PN}

	newicon "nb/${PN}.png" "${PN}.png"
	make_desktop_entry "${PN}" "Netbeans" "${PN}" "Development;"
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_icon_cache_update
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_icon_cache_update
}
