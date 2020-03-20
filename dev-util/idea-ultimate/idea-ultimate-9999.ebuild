# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit desktop eutils

DESCRIPTION="The most intelligent Java IDE."
HOMEPAGE="https://www.jetbrains.com/idea"
LICENSE="IDEA || ( IDEA_Academic IDEA_Classroom IDEA_OpenSource IDEA_Personal )"

SLOT="0"

IUSE="android -custom-jdk groovy kotlin spy-js svn"
RDEPEND="virtual/jdk"

MY_PN="idea"

if [[ ${PV} != 9999 ]]; then
        SRC_URI="https://download.jetbrains.com/${MY_PN}/${MY_PN}IU-${PV}.tar.gz"
        KEYWORDS="*"
fi

S="${WORKDIR}/${MY_PN}IU-${PV}"

src_unpack() {
        default
        mv "${WORKDIR}"/idea* "${S}" || die "Failed to move/rename source dir"
}

src_prepare() {
        default
	if ! use custom-jdk; then
		if [[ -d jre64 ]]; then
			rm -r jre64 || die
		fi
	fi
}

src_install() {
	local dir="/opt/${PN}-${PV}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/bin/idea.sh

	if use amd64; then
		fperms 755 "${dir}"/bin/fsnotifier64
	fi
	if use x86; then
		fperms 755 "${dir}"/bin/fsnotifier
	fi

	if use custom-jdk; then
		if [[ -d jbr ]]; then
		fperms 755 "${dir}"/jbr/bin/{jaotc,java,javac,jdb,jjs,jrunscript,keytool,pack200,rmid,rmiregistry,serialver,unpack200}
		fi
	fi

	make_wrapper "${PN}" "${dir}/bin/${MY_PN}.sh"
	newicon "bin/${MY_PN}.svg" "${PN}.svg"
	make_desktop_entry "${PN}" "IntelliJ Idea Ultimate" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	mkdir -p "${D}/etc/sysctl.d/" || die
	echo "fs.inotify.max_user_watches = 524288" > "${D}/etc/sysctl.d/30-idea-inotify-watches.conf" || die
}

