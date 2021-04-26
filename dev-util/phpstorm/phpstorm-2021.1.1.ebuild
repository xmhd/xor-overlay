# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit desktop wrapper

DESCRIPTION="A complete toolset for C and C++ development."
HOMEPAGE="https://www.jetbrains.com/clion"
SRC_URI="https://download.jetbrains.com/webide/PhpStorm-${PV}.tar.gz"

LICENSE="
	|| ( jetbrains_business-3.1 jetbrains_individual-4.1 jetbrains_education-3.2 jetbrains_classroom-4.1 jetbrains_open_source-4.1 )
	Apache-1.1 Apache-2.0 BSD BSD-2 CC0-1.0 CC-BY-2.5 CDDL CDDL-1.1 codehaus CPL-1.0 GPL-2 GPL-2-with-classpath-exception GPL-3 ISC LGPL-2.1 LGPL-3 MIT MPL-1.1 MPL-2.0 OFL trilead-ssh yFiles yourkit W3C ZLIB
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

S="${WORKDIR}/${MY_PN}-${PV}"

src_unpack() {
	default
	mv "${WORKDIR}"/PhpStorm* "${S}" || die "Failed to move/rename source dir"
}

src_prepare() {
	default

	# Remove any bundled Java
	rm -rf {jbr,jre{64}} || die "Failed to remove bundled Java"
}

src_install() {

	insinto "/opt/${PN}"
	doins -r *

	fperms 755 /opt/${PN}/bin/{format.sh,phpstorm.sh,inspect.sh,printenv.py,restart.py,fsnotifier{,64}}

	dosym ../../opt/${PN}/bin/phpstorm.sh /usr/bin/${PN}

	newicon "bin/${PN}.png" "${PN}.png"
	make_desktop_entry "${PN}" "PhpStorm" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /etc/sysctl.d
	echo "fs.inotify.max_user_watches = 524288" > "${D}/etc/sysctl.d/30-idea-inotify-watches.conf" || die
}
