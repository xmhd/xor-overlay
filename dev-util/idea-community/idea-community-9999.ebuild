# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit gnome2-utils xdg

DESCRIPTION="The most intelligent Java IDE."
HOMEPAGE="https://www.jetbrains.com/idea"
LICENSE="Apache-2.0"

SLOT="0"

BDEPEND="
	app-arch/tar
"

RDEPEND="
	virtual/jdk
	dev-libs/libdbusmenu
"

RESTRICT="bindist mirror strip"

QA_PREBUILT="
	/opt/${PN}/bin/fsnotifier
	/opt/${PN}/bin/fsnotifier64
	/opt/${PN}/bin/libdbm64.so
"

MY_PN="idea"
S="${WORKDIR}/${MY_PN}IC-${PV}"

if [[ ${PV} != 9999 ]]; then
        SRC_URI="https://download.jetbrains.com/${MY_PN}/${MY_PN}IC-${PV}.tar.gz"
        KEYWORDS="*"
fi

src_unpack() {
        default
        mv "${WORKDIR}"/idea* "${S}" || die "Failed to move/rename source dir"
}

src_prepare() {
        default

	# Remove any bundled Java
	rm -rf {jbr,jre{64}} || die "Failed to remove bundled Java"
}

src_install() {

	insinto "/opt/${PN}"
	doins -r *

	fperms 755 /opt/${PN}/bin/{format.sh,idea.sh,inspect.sh,printenv.py,restart.py,fsnotifier{,64}}

	dosym ../../opt/${PN}/bin/idea.sh /usr/bin/${PN}

	newicon "bin/${MY_PN}.png" "${PN}.png"
	make_desktop_entry "${PN}" "IntelliJ IDEA Community" "${PN}" "Development;Programming;IDE;"

        # recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
        mkdir -p "${D}/etc/sysctl.d/" || die
        echo "fs.inotify.max_user_watches = 524288" > "${D}/etc/sysctl.d/30-idea-inotify-watches.conf" || die
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_icon_cache_update
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_icon_cache_update
}
