# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit desktop wrapper

DESCRIPTION="Cross-platform .NET IDE"
HOMEPAGE="https://www.jetbrains.com/rider"
SRC_URI="https://download.jetbrains.com/rider/JetBrains.Rider-${PV}.tar.gz"

LICENSE="
	|| (
		JetBrains_Business
		JetBrains_Classroom
		JetBrains_Educational
		JetBrains_OpenSource
		JetBrains_Personal
	)
"
KEYWORDS="amd64"

SLOT="0"

BDEPEND="
	app-arch/tar
"

RDEPEND="
	virtual/jdk
"

RESTRICT="bindist mirror strip"

S="${WORKDIR}/${PN}-${PV}"

src_unpack() {
	default
	mv "${WORKDIR}"/JetBrains* "${S}" || die "Failed to move/rename source dir"
}

src_prepare() {
	default

	# Remove any bundled Java
	rm -rf {jbr,jre{64}} || die "Failed to remove bundled Java"
}

src_install() {

	insinto "/opt/${PN}"
	doins -r *

	fperms 755 /opt/${PN}/bin/{format.sh,rider.sh,inspect.sh,printenv.py,restart.py,fsnotifier{,64}}

	dosym ../../opt/${PN}/bin/rider.sh /usr/bin/${PN}

	newicon "bin/${PN}.png" "${PN}.png"
	make_desktop_entry "${PN}" "Rider" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /etc/sysctl.d
	echo "fs.inotify.max_user_watches = 524288" > "${D}/etc/sysctl.d/30-idea-inotify-watches.conf" || die
}
