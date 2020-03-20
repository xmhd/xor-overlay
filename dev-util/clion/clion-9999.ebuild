# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit desktop eutils

DESCRIPTION="A complete toolset for C and C++ development."
HOMEPAGE="https://www.jetbrains.com/clion"
LICENSE="IDEA || ( IDEA_Academic IDEA_Classroom IDEA_OpenSource IDEA_Personal )"

SLOT="0"

IUSE="custom-jdk"

RDEPEND="
        dev-util/cmake
        sys-devel/gdb
        !custom-jdk? ( virtual/jdk )"

MY_PN="clion"

if [[ ${PV} != 9999 ]]; then
        SRC_URI="https://download.jetbrains.com/cpp/CLion-${PV}.tar.gz"
        KEYWORDS="*"
fi

S="${WORKDIR}/${MY_PN}-${PV}"

src_unpack() {
        default
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
	local dir="/opt/${MY_PN}-${MY_PV}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/bin/{clion.sh,clang/linux/clang{d,-tidy}}

	if use amd64; then
		fperms 755 "${dir}"/bin/fsnotifier64
	fi
	if use arm; then
		fperms 755 "${dir}"/bin/fsnotifier-arm
	fi
	if use x86; then
		fperms 755 "${dir}"/bin/fsnotifier
	fi

	if use custom-jdk; then
		if [[ -d jbr ]]; then
		fperms 755 "${dir}"/jbr/bin/{jaotc,java,javac,jdb,jjs,jrunscript,keytool,pack200,rmid,rmiregistry,serialver,unpack200}
		fi
	fi

	make_wrapper "${MY_PN}" "${dir}/bin/${MY_PN}.sh"
	newicon "bin/${MY_PN}.svg" "${MY_PN}.svg"
	make_desktop_entry "${MY_PN}" "CLion" "${MY_PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-clion-inotify-watches.conf" || die
}