# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit desktop wrapper

DESCRIPTION="The Python IDE for pure Python development"
HOMEPAGE="https://www.jetbrains.com/pycharm"

MY_PN="${PN%-*}"
SRC_URI="https://download.jetbrains.com/python/${PN}-${PV}.tar.gz"

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
	dev-python/pip
"

RESTRICT="bindist mirror strip"

S="${WORKDIR}/${PN}-${PV}"

src_unpack() {
	default
}

src_prepare() {
	default

	# Remove any bundled Java
	rm -rf {jbr,jre{64}} || die "Failed to remove bundled Java"
}

src_install() {

	local dir="/opt/${PN}"

	insinto "${dir}"
	doins -r *

	fperms 755 "${dir}"/bin/{${MY_PN}.sh

	make_wrapper "${PN}" "${dir}"/bin/${MY_PN}.sh

	newicon "bin/${MY_PN}.svg" "${PN}.svg"
	make_desktop_entry "${PN}" "PyCharm Community" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /etc/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/etc/sysctl.d/30-idea-inotify-watches.conf" || die
}
