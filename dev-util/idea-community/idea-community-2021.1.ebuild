# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit desktop wrapper

DESCRIPTION="The most intelligent Java IDE."
HOMEPAGE="https://www.jetbrains.com/idea"

MY_PN="${PN%-*}"
SRC_URI="https://download.jetbrains.com/${MY_PN}/${MY_PN}IC-${PV}.tar.gz"

LICENSE="
	JetBrains_Community
	Apache-2.0
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

QA_PREBUILT="
	/opt/${PN}/bin/fsnotifier
	/opt/${PN}/bin/fsnotifier64
	/opt/${PN}/bin/libdbm64.so
"

S="${WORKDIR}/${MY_PN}IC-${PV}"

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
	make_desktop_entry "${PN}" "IntelliJ IDEA Community" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /etc/sysctl.d
	echo "fs.inotify.max_user_watches = 524288" > "${D}/etc/sysctl.d/30-idea-inotify-watches.conf" || die
}
