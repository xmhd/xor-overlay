# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit desktop wrapper

DESCRIPTION="A complete toolset for C and C++ development."
HOMEPAGE="https://www.jetbrains.com/clion"
SRC_URI="https://download.jetbrains.com/cpp/CLion-${PV}.tar.gz"

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

IUSE="gdb lldb"

BDEPEND="
	app-arch/tar
"

RDEPEND="
	dev-util/cmake
	gdb? ( sys-devel/gdb )
	lldb? ( dev-util/lldb )
	virtual/jdk
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

	insinto "/opt/${PN}"
	doins -r *

	fperms 755 /opt/${PN}/bin/{clion.sh,clang/linux/clang{d,-tidy},fsnotifier{,64}}

	dosym ../../opt/${PN}/bin/clion.sh /usr/bin/${PN}

	newicon "bin/${PN}.png" "${PN}.png"
	make_desktop_entry "${PN}" "CLion" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /etc/sysctl.d
	echo "fs.inotify.max_user_watches = 524288" > "${D}/etc/sysctl.d/30-idea-inotify-watches.conf" || die
}
