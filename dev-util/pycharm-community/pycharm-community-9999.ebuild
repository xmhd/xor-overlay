# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit desktop eutils

DESCRIPTION="The Python IDE for pure Python development"
HOMEPAGE="https://www.jetbrains.com/pycharm"
LICENSE="IDEA || ( IDEA_Academic IDEA_Classroom IDEA_OpenSource IDEA_Personal )"

SLOT="0"

IUSE="custom-jdk"
RDEPEND="
        !custom-jdk? ( virtual/jdk )
        dev-python/pip"

MY_PN="pycharm-community"

if [[ ${PV} != 9999 ]]; then
        SRC_URI="https://download.jetbrains.com/python/${MY_PN}-${PV}.tar.gz"
        KEYWORDS="*"
fi

S="${WORKDIR}/${MY_PN}-${PV}"

src_unpack() {
        default
        mv "${WORKDIR}"/pycharm* "${S}" || die "Failed to move/rename source dir"
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
	local dir="/opt/${MY_PN}-${PV}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/bin/pycharm.sh

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

	make_wrapper "${PN}" "${dir}/bin/pycharm.sh"
	newicon "bin/${PN}.svg" "${PN}.svg"
	make_desktop_entry "${PN}" "PyCharm Community" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	mkdir -p "${D}/etc/sysctl.d/" || die
	echo "fs.inotify.max_user_watches = 524288" > "${D}/etc/sysctl.d/30-idea-inotify-watches.conf" || die
}
