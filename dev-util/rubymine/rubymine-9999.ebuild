# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit gnome2-utils xdg

DESCRIPTION="The most intelligent Ruby and Rails IDE."
HOMEPAGE="https://www.jetbrains.com/rubymine"
LICENSE="JetBrains"

SLOT="0"

BDEPEND="
	app-arch/tar
"

RDEPEND="
	virtual/jdk
"

RESTRICT="bindist mirror splitdebug strip"

if [[ ${PV} != 9999 ]]; then
        SRC_URI="https://download.jetbrains.com/ruby/RubyMine-${PV}.tar.gz"
        KEYWORDS="*"
fi

S="${WORKDIR}/${PN}-${PV}"

src_unpack() {
        default
        mv "${WORKDIR}"/RubyMine* "${S}" || die "Failed to move/rename source dir"
}

src_prepare() {
        default

	# Remove any bundled Java
	rm -rf {jbr,jre{64}} || die "Failed to remove bundled Java"
}

src_install() {

	insinto "/opt/${PN}"
	doins -r *

	fperms 755 /opt/${PN}/bin/{format.sh,rubymine.sh,printenv.py,restart.py,fsnotifier{,64}}

	dosym ../../opt/${PN}/bin/rubymine.sh /usr/bin/${PN}

	newicon "bin/${PN}.png" "${PN}.png"
	make_desktop_entry "${PN}" "RubyMine" "${PN}" "Development;Programming;IDE;"

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
