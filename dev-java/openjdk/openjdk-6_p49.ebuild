# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit check-reqs eapi7-ver flag-o-matic java-pkg-2 java-vm-2 multiprocessing pax-utils toolchain-funcs

# we need latest -ga tag from hg, but want to keep build number as well
# as _p component of the gentoo version string.

MY_PV=$(ver_rs 1 'u' 2 '-' ${PV%_p*}-ga)

BASE_URI="https://hg.${PN}.java.net/jdk6/jdk6"

DESCRIPTION="Open source implementation of the Java programming language"
HOMEPAGE="https://openjdk.java.net"
SRC_URI="
	${BASE_URI}/archive/jdk6-b49.tar.gz -> ${PN}-6_p49.tar.gz
	${BASE_URI}/corba/archive/jdk6-b49.tar.gz -> ${PN}-corba-6.p_49.tar.gz
	${BASE_URI}/hotspot/archive/jdk6-b49.tar.gz -> ${PN}-hotspot-6_p49.tar.gz
	${BASE_URI}/jaxp/archive/jdk6-b49.tar.gz -> ${PN}-jaxp-6_p49.tar.gz
	${BASE_URI}/jaxws/archive/jdk6-b49.tar.gz -> ${PN}-jaxws-6_p49.tar.gz
	${BASE_URI}/jdk/archive/jdk6-b49.tar.gz -> ${PN}-jdk-6_p49.tar.gz
	${BASE_URI}/langtools/archive/jdk6-b49.tar.gz -> ${PN}-langtools-6_p49.tar.gz
"

LICENSE="GPL-2"
SLOT="$(ver_cut 1)"
KEYWORDS="~amd64"
IUSE="alsa debug cups doc examples headless-awt javafx +jbootstrap +pch selinux source"

COMMON_DEPEND="
	media-libs/freetype:2=
	media-libs/giflib:0/7
	sys-libs/zlib
"
# Many libs are required to build, but not to run, make is possible to remove
# by listing conditionally in RDEPEND unconditionally in DEPEND
RDEPEND="
	${COMMON_DEPEND}
	>=sys-apps/baselayout-java-0.1.0-r1
	!headless-awt? (
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXi
		x11-libs/libXrender
		x11-libs/libXt
		x11-libs/libXtst
	)
	alsa? ( media-libs/alsa-lib )
	cups? ( net-print/cups )
	selinux? ( sec-policy/selinux-java )
"

DEPEND="
	${COMMON_DEPEND}
	app-arch/zip
	media-libs/alsa-lib
	net-print/cups
	x11-base/xorg-proto
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXi
	x11-libs/libXrender
	x11-libs/libXt
	x11-libs/libXtst
	|| (
		dev-java/openjdk-bin:${SLOT}
		dev-java/icedtea-bin:${SLOT}
		dev-java/openjdk:${SLOT}
		dev-java/icedtea:${SLOT}
	)
"

PDEPEND="javafx? ( dev-java/openjfx:${SLOT} )"

# The space required to build varies wildly depending on USE flags,
# ranging from 2GB to 16GB. This function is certainly not exact but
# should be close enough to be useful.
openjdk_check_requirements() {
	local M
	M=2048
	M=$(( $(usex debug 3 1) * $M ))
	M=$(( $(usex jbootstrap 2 1) * $M ))
	M=$(( $(usex doc 320 0) + $(usex source 128 0) + 192 + $M ))

	CHECKREQS_DISK_BUILD=${M}M check-reqs_pkg_${EBUILD_PHASE}
}

pkg_pretend() {
	openjdk_check_requirements
	if [[ ${MERGE_TYPE} != binary ]]; then
		has ccache ${FEATURES} && die "FEATURES=ccache doesn't work with ${PN}, bug #677876"
	fi
}

pkg_setup() {
	openjdk_check_requirements

	JAVA_PKG_WANT_BUILD_VM="openjdk-${SLOT} openjdk-bin-${SLOT} icedtea-bin-$((SLOT-1)) icedtea-${SLOT} icedtea-bin-${SLOT} openjdk-$((SLOT-1)) openjdk-bin-$((SLOT-1)) icedtea-$((SLOT-1)) openjdk-$((SLOT+1)) openjdk-bin-$((SLOT+1)) openjdk-8"
	JAVA_PKG_WANT_SOURCE="${SLOT}"
	JAVA_PKG_WANT_TARGET="${SLOT}"

	java-vm-2_pkg_setup
	java-pkg-2_pkg_setup
}

src_unpack() {
	default
	mv -v "jdk${SLOT}"* "${P}" || die

	local repo
	for repo in corba hotspot jdk jaxp jaxws langtools; do
		mv -v "${repo}-"* "${P}/${repo}" || die
	done
}

src_prepare() {
	default

	# new warnings in new gcc https://bugs.gentoo.org/685426
	sed -i '/^WARNINGS_ARE_ERRORS/ s/-Werror/-Wno-error/' \
		hotspot/make/linux/makefiles/gcc.make || die
}

src_configure() {
	# general build info found here:
	#https://hg.openjdk.java.net/jdk8/jdk8/raw-file/tip/README-builds.html

	# Work around stack alignment issue, bug #647954.
	use x86 && append-flags -mincoming-stack-boundary=2

	# Work around -fno-common ( GCC10 default ), bug #706638
	append-flags -fcommon

	tc-export_build_env CC CXX PKG_CONFIG STRIP

	unset JAVA_HOME JDK_HOME CLASSPATH JAVAC JAVACFLAGS
}

src_compile() {

	export ANT_HOME="/usr/share/ant"

	# Would use GENTOO_VM otherwise.
	export ANT_RESPECT_JAVA_HOME=TRUE

	# With ant >=1.8.2 all required tasks are part of ant-core
	export ANT_TASKS="none"

	export ALT_BOOTDIR="$(java-config -O)"

	export SHOW_ALL_WARNINGS="true"

	# icedtea doesn't like some locales. #330433 #389717
	export LANG="C" LC_ALL="C"

	emake sanity
}

src_install() {
	local dest="/usr/$(get_libdir)/${PN}-${SLOT}"
	local ddest="${ED%/}/${dest#/}"

	cd "${S}"/build/*-release/images/j2sdk-image || die

	if ! use alsa; then
		rm -v jre/lib/$(get_system_arch)/libjsoundalsa.* || die
	fi

	# build system does not remove that
	if use headless-awt ; then
		rm -fvr jre/lib/$(get_system_arch)/lib*{[jx]awt,splashscreen}* \
		{,jre/}bin/policytool bin/appletviewer || die
	fi

	if ! use examples ; then
		rm -vr demo/ || die
	fi

	if ! use source ; then
		rm -v src.zip || die
	fi

	dodir "${dest}"
	cp -pPR * "${ddest}" || die

	dosym ../../../../../../etc/ssl/certs/java/cacerts "${dest}"/jre/lib/security/cacerts

	java-vm_install-env "${FILESDIR}"/${PN}-${SLOT}.env.sh
	java-vm_set-pax-markings "${ddest}"
	java-vm_revdep-mask
	java-vm_sandbox-predict /dev/random /proc/self/coredump_filter

	if use doc ; then
		docinto html
		dodoc -r "${S}"/build/*-release/docs/*
	fi
}

pkg_postinst() {
	java-vm-2_pkg_postinst
	einfo "JavaWebStart functionality provided by icedtea-web package"
}
