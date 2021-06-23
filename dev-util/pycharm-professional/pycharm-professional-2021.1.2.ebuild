# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit desktop wrapper

DESCRIPTION="The Python IDE for Professional Developers"
HOMEPAGE="https://www.jetbrains.com/pycharm"

MY_PN="${PN}%-*"
SRC_URI="https://download.jetbrains.com/python/${PN}-${PV}.tar.gz"

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
	dev-python/pip
"

RESTRICT="bindist mirror strip"

QA_PREBUILT="
	opt/${PN}/bin/fsnotifier
	opt/${PN}/bin/fsnotifier64
	opt/${PN}/bin/fsnotifier-arm
	opt/${PN}/bin/libyjpagent-linux.so
	opt/${PN}/bin/libyjpagent-linux64.so
"

S="${WORKDIR}/${PN}-${PV}"

src_unpack() {
	default
	mv "${WORKDIR}"/pycharm* "${S}" || die "Failed to move/rename source dir"
}

src_prepare() {
	default

	# Remove any bundled Java
	rm -rf {jbr,jre{64}} || die "Failed to remove bundled Java"
}

src_install() {

	insinto "/opt/${PN}"
	doins -r *

	fperms 755 /opt/${PN}/bin/{pycharm.sh,fsnotifier{,64},inspect.sh}

	dosym ../../opt/${PN}/bin/pycharm.sh /usr/bin/${PN}

	newicon "bin/${MY_PN}.png" "${PN}.png"
	make_desktop_entry "${PN}" "PyCharm Professional" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /etc/sysctl.d
	echo "fs.inotify.max_user_watches = 524288" > "${D}/etc/sysctl.d/30-idea-inotify-watches.conf" || die
}
