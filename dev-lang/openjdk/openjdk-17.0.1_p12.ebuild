# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit autotools check-reqs flag-o-matic java-pkg-2 java-vm-2 multiprocessing pax-utils toolchain-funcs

MY_PV="${PV/_p/+}"
FULL_VERSION="${PV%_p*}"
SLOT=$(get_major_version)

DESCRIPTION="Open source implementation of the Java programming language"
HOMEPAGE="https://openjdk.java.net"

SRC_URI+="
	https://github.com/openjdk/jdk${SLOT}u/archive/jdk-${PV%_p*}-ga.tar.gz -> ${P}.tar.gz

	!system-bootstrap? (
		amd64? (
			elibc_glibc? ( https://github.com/adoptium/temurin${SLOT}-binaries/releases/download/jdk-17.0.1%2B12/OpenJDK${SLOT}U-jdk_x64_linux_hotspot_${MY_PV//+/_}.tar.gz )
			elibc_musl? ( https://github.com/adoptium/temurin${SLOT}-binaries/releases/download/jdk-17.0.1%2B12/OpenJDK${SLOT}U-jdk_x64_alpine-linux_hotspot_${MY_PV//+/_}.tar.gz )
		)
	)
"

LICENSE="GPL-2-with-classpath-exception"
KEYWORDS="~amd64"

IUSE="alsa +bootstrap cups debug doc examples headless-awt javafx +pch selinux source system-bootstrap systemtap"

COMMON_DEPEND="
	media-libs/freetype:2=
	media-libs/giflib:0/7
	media-libs/libpng:0=
	media-libs/lcms:2=
	sys-libs/zlib
	virtual/jpeg:0=
	systemtap? ( dev-util/systemtap )
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
		x11-libs/libXrandr
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
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXt
	x11-libs/libXtst
	javafx? ( dev-java/openjfx:${SLOT}= )
	|| (
		dev-java/openjdk-bin:${SLOT}
		dev-java/openjdk:${SLOT}
		dev-java/openjdk-bin:$((SLOT-1))
		dev-java/openjdk:$((SLOT-1))
	)
"

REQUIRED_USE="
	javafx? ( alsa !headless-awt )
"

S="${WORKDIR}/jdk${SLOT}u-jdk-${PV/_p/-}"

pkg_pretend() {

	if [[ ${MERGE_TYPE} != binary ]]; then

		# Disk space required to build varies (2GB to 16GB ) depending on USE flags.
		# This function is certainly not exact but should be close enough to be useful.
		local M
		M=2048
		M=$(( $(usex bootstrap 2 1) * ${M} ))
		M=$(( $(usex debug 3 1) * ${M} ))
		M=$(( $(usex doc 320 0) + $(usex source 128 0) + 192 + ${M} ))

		CHECKREQS_DISK_BUILD=${M}M check-reqs_pkg_setup

		if has ccache ${FEATURES}; then
			die "FEATURES=ccache doesn't work with ${PN}"
		fi
	fi
}

pkg_setup() {

	JAVA_PKG_WANT_BUILD_VM="openjdk-${SLOT} openjdk-bin-${SLOT} openjdk-$((SLOT-1)) openjdk-bin-$((SLOT-1))"
	JAVA_PKG_WANT_SOURCE="${SLOT}"
	JAVA_PKG_WANT_TARGET="${SLOT}"

	java-vm-2_pkg_setup
	java-pkg-2_pkg_setup

	VENDOR="Gentoo Linux"
	VENDOR_URL="https://gentoo.org"
	VENDOR_BUG_URL="https://bugs.gentoo.org"
	VENDOR_VM_BUG_URL="https://bugs.openjdk.java.net"
	VENDOR_VERSION_STRING="${PVR}"

	if ! use system-bootstrap; then
		export JAVA_HOME="${WORKDIR}/jdk-${MY_PV}"

		echo ${JAVA_HOME}
	fi
}

src_prepare() {
	eapply_user

	chmod +x configure || die
}

src_configure() {
	# Work around stack alignment issue, bug #647954. in case we ever have x86
	use x86 && append-flags -mincoming-stack-boundary=2

	# Work around -fno-common ( GCC10 default ), bug #713180
	append-flags -fcommon

	# Enabling full docs appears to break doc building. If not
	# explicitly disabled, the flag will get auto-enabled if pandoc and
	# graphviz are detected. pandoc has loads of dependencies anyway.

	local myconf=(
		--disable-ccache
		--enable-full-docs=no
		--with-boot-jdk="${JDK_HOME}"
		--with-extra-cflags="${CFLAGS}"
		--with-extra-cxxflags="${CXXFLAGS}"
		--with-extra-ldflags="${LDFLAGS}"
		--with-giflib=system
		--with-lcms=system
		--with-libjpeg=system
		--with-libpng=system
		--with-native-debug-symbols=$(usex debug internal none)
		--with-vendor-name="${VENDOR}"
		--with-vendor-url="${VENDOR_URL}"
		--with-vendor-bug-url="${VENDOR_BUG_URL}"
		--with-vendor-vm-bug-url="${VENDOR_VM_BUG_URL}"
		--with-vendor-version-string="${VENDOR_VERSION_STRING}"
		--with-version-pre=""
		--with-version-string="${PV%_p*}"
		--with-version-build="${PV#*_p}"
		--with-zlib=system
		--disable-warnings-as-errors
		--enable-dtrace=$(usex systemtap yes no)
		--enable-headless-only=$(usex headless-awt yes no)
		$(tc-is-clang && echo "--with-toolchain-type=clang")
	)

	if use javafx; then
		local zip="${EPREFIX%/}/usr/$(get_libdir)/openjfx-${SLOT}/javafx-exports.zip"
		if [[ -r ${zip} ]]; then
			myconf+=( --with-import-modules="${zip}" )
		else
			die "${zip} not found or not readable"
		fi
	fi

	# PaX breaks pch, bug #601016
	if use pch && ! host-is-pax; then
		myconf+=( --enable-precompiled-headers )
	else
		myconf+=( --disable-precompiled-headers )
	fi

	(
		unset _JAVA_OPTIONS JAVA JAVA_TOOL_OPTIONS JAVAC XARGS
		CFLAGS= CXXFLAGS= LDFLAGS= \
		CONFIG_SITE=/dev/null \
		econf "${myconf[@]}"
	)
}

src_compile() {
	local myemakeargs=(
		JOBS=$(makeopts_jobs)
		LOG=debug
		ALL_NAMED_TESTS= # Build error
		$(usex doc docs '')
		$(usex bootstrap bootcycle-images product-images)
	)
	emake "${myemakeargs[@]}" -j1 #nowarn
}

src_install() {
	local dest="/usr/$(get_libdir)/${PN}-${SLOT}"
	local ddest="${ED}${dest#/}"

	cd "${S}"/build/*-release/images/jdk || die

	# Create files used as storage for system preferences.
	mkdir .systemPrefs || die
	touch .systemPrefs/.system.lock || die
	touch .systemPrefs/.systemRootModFile || die

	# Oracle and IcedTea have libjsoundalsa.so depending on
	# libasound.so.2 but OpenJDK only has libjsound.so. Weird.
	if ! use alsa ; then
		rm -v lib/libjsound.* || die
	fi

	if ! use examples ; then
		rm -vr demo/ || die
	fi

	if ! use source ; then
		rm -v lib/src.zip || die
	fi

	rm -v lib/security/cacerts || die

	dodir "${dest}"
	cp -pPR * "${ddest}" || die

	dosym ../../../../../etc/ssl/certs/java/cacerts "${dest}"/lib/security/cacerts

	# must be done before running itself
	java-vm_set-pax-markings "${ddest}"

	einfo "Creating the Class Data Sharing archives and disabling usage tracking"
	"${ddest}/bin/java" -server -Xshare:dump -Djdk.disableLastUsageTracking || die

	java-vm_install-env "${FILESDIR}"/${PN}-${SLOT}.env.sh
	java-vm_revdep-mask
	java-vm_sandbox-predict /dev/random /proc/self/coredump_filter

	if use doc ; then
		docinto html
		dodoc -r "${S}"/build/*-release/images/docs/*
		dosym ../../../usr/share/doc/"${PF}" /usr/share/doc/"${PN}-${SLOT}"
	fi
}

pkg_postinst() {
	java-vm-2_pkg_postinst
}
