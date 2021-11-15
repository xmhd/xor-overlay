# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit desktop wrapper

DESCRIPTION="Many databases, one tool"
HOMEPAGE="https://www.jetbrains.com/datagrip"
SRC_URI="https://download.jetbrains.com/datagrip/${PN}-${PV}.tar.gz"

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
	dev-libs/libdbusmenu
"

RESTRICT="bindist mirror strip"

MY_PN="datagrip"
S="${WORKDIR}/${MY_PN}-${PV}"

src_unpack() {
	default
	mv "${WORKDIR}"/DataGrip* "${S}" || die "Failed to move/rename source dir"
}

src_prepare() {
	default

	# Remove any bundled Java
	rm -rf {jbr,jre{64}} || die "Failed to remove bundled Java"
}

src_install() {

	insinto "/opt/${PN}"
	doins -r *

	fperms 755 /opt/${PN}/bin/{format.sh,datagrip.sh,inspect.sh,printenv.py,restart.py,fsnotifier{,64}}

	dosym ../../opt/${PN}/bin/datagrip.sh /usr/bin/${PN}

	newicon "bin/${PN}.png" "${PN}.png"
	make_desktop_entry "${PN}" "DataGrip" "${PN}" "Development;Programming;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	mkdir -p "${D}"/etc/sysctl.d/ || die
	echo "fs.inotify.max_user_watches = 524288" > "${D}"/etc/sysctl.d/30-idea-inotify-watches.conf || die
}
