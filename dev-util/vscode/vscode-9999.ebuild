# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit gnome2-utils pax-utils xdg

DESCRIPTION="Multiplatform Visual Studio Code from Microsoft"
HOMEPAGE="https://code.visualstudio.com"
LICENSE="MIT"

SLOT="0"

IUSE="gnome-keyring"

BDEPEND="
	app-arch/tar
"

RDEPEND="
	>=x11-libs/cairo-1.14.12:0
	>=net-print/cups-2.0.0
	>=gnome-base/gconf-3.2.6-r4:2
	>=x11-libs/gtk+-2.24.31-r1:2
	x11-libs/libnotify
	>=media-libs/libpng-1.2.46:0
	gnome-keyring? ( app-crypt/libsecret[crypt] )
	x11-libs/libXScrnSaver
	>=x11-libs/libXtst-1.2.3:0
	dev-libs/nss
"

RESTRICT="bindist mirror strip"

S="${WORKDIR}/VSCode-linux-x64"

QA_PREBUILT="/opt/${PN}/code"
QA_PRESTRIPPED="/opt/${PN}/code"

if [[ ${PV} != 9999 ]]; then
        SRC_URI="https://update.code.visualstudio.com/${PV}/linux-x64/stable -> ${PN}-${PV}-amd64.tar.gz"
	KEYWORDS="amd64"
fi

src_install() {

	insinto "/opt/${PN}"
	doins -r *

	# Set PaX flags
	pax-mark m code

	fperms 755 /opt/${PN}/code
	fperms 755 /opt/${PN}/bin/code
	fperms 755 /opt/${PN}/resources/app/node_modules.asar.unpacked/vscode-ripgrep/bin/rg
	fperms 755 /opt/${PN}/resources/app/extensions/git/dist/askpass.sh

	dosym ../../opt/${PN}/bin/code /usr/bin/${PN}

	newicon "${FILESDIR}/${PN}.png" "${PN}.png"
	make_desktop_entry "${PN}" "Visual Studio Code" "${PN}" "Development;Programming;IDE;"

	for i in resources/app/LICEN*;
	do
		newins "${i}" "`basename ${i}`"
	done
	for i in resources/app/licenses/*;
	do
		newins "${i}" "`basename ${i}`"
	done
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_icon_cache_update
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_icon_cache_update
}
