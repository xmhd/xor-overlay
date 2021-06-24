# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit eutils flag-o-matic gnuconfig libtool multilib toolchain-funcs

DESCRIPTION="Tools necessary to build programs"
HOMEPAGE="https://sourceware.org/binutils/"

LICENSE="GPL-3+"
KEYWORDS="~amd64"

SLOT="${PV%_*}"

IUSE="bpf cet default-gold doc +gas +gold +ld multitarget +nls +plugins static-libs test vanilla"

REQUIRED_USE="
	default-gold? ( gold )
"

RDEPEND="
	>=sys-devel/binutils-config-3
	sys-libs/zlib
"

DEPEND="${RDEPEND}"

BDEPEND="
	doc? ( sys-apps/texinfo )
	test? (
		sys-devel/bc
		dev-util/dejagnu
	)
	nls? ( sys-devel/gettext )
	sys-devel/flex
	virtual/yacc
"

RESTRICT="!test? ( test )"

BINUTILS_VER="${PV%_*}"
BINUTILS_PATCH_VER="${PV##*p}"

SRC_URI="
	mirror://gnu/binutils/binutils-${BINUTILS_VER}.tar.xz
"

S="${WORKDIR}/${PN}-${BINUTILS_VER}"

GENTOO_PATCHES_DIR="${FILESDIR}/${BINUTILS_VER}/gentoo-patches"

GENTOO_PATCHES=(
	0001-Revert-Remove-newline-that-isn-t-in-the-tarball.patch
	0002-Reset-development-back-to-true.patch
	0004-ld-Remove-x86-ISA-level-run-time-tests.patch
	0006-Gentoo-gold-ld-add-support-for-poisoned-system-direc.patch
	0007-Gentoo-libiberty-install-PIC-version-of-libiberty.a.patch
	0008-Gentoo-opcodes-link-against-libbfd.la-for-rpath-deps.patch
	0009-Gentoo-add-with-extra-soversion-suffix-option.patch
	0010-Gentoo-ld-enable-new-dtags-by-default-for-linux-gnu-.patch
	0011-Gentoo-Pass-hash-style-sysv-to-ld-in-the-testsuite.patch
	0012-PR27382-build-failure-if-fileno-is-a-macro.patch
	0013-IBM-Z-Implement-instruction-set-extensions.patch
	0014-binutils-Avoid-renaming-over-existing-files.patch
	0015-Reinstate-various-pieces-backed-out-from-smart_renam.patch
	0016-PR27456-lstat-in-rename.c-on-MinGW.patch
	0017-Use-make_tempname-file-descriptor-in-smart_rename.patch
	0018-Re-Use-make_tempname-file-descriptor-in-smart_rename.patch
	0019-PR27441-inconsistency-in-weak-definitions.patch
	0020-PowerPC64-undefined-weak-visibility-vs-GOT-optimisat.patch
	0021-Add-install-dependencies-for-ld-bfd-and-libctf-bfd.patch
	0022-DWARF-Check-version-3-for-DW_FORM_ref_addr.patch
	0023-PE-Windows-x86_64-Fix-weak-undef-symbols-after-image.patch
	0024-AArch64-Fix-Atomic-LD64-ST64-classification.patch
	0025-AArch64-Fix-Diagnostic-messaging-for-LD-ST-Exclusive.patch
	0026-Make-objcopy-p-work-when-an-output-file-is-specified.patch
	0028-GCC_CET_HOST_FLAGS-Check-if-host-supports-multi-byte.patch
	9999-Gentoo-We-make-a-release.patch
)

is_cross() { [[ ${CHOST} != ${CTARGET} ]] ; }

pkg_pretend() {

	if [[ ${CTARGET} == *-uclibc* ]] ; then
		if grep -qs 'linux-gnu' "${S}"/ltconfig ; then
			die "sorry, but this binutils doesn't yet support uClibc :("
		fi
	fi
}

pkg_setup() {

	# export branding
	# TODO: hardened etc?
	export BINUTILS_BRANDING="Cairn Linux ${PV}"

	#
	# The cross-compile logic
	#
	export CTARGET=${CTARGET:-${CHOST}}
	if [[ ${CTARGET} == ${CHOST} ]] ; then
		if [[ ${CATEGORY} == cross-* ]] ; then
			export CTARGET=${CATEGORY#cross-}
		fi
	fi
}

src_unpack() {
	default
}

src_prepare() {

	if ! use vanilla; then
		# Gentoo Linux patches
		einfo "Applying Gentoo Linux patches ..."
		for my_patch in ${GENTOO_PATCHES[*]} ; do
		    eapply "${GENTOO_PATCHES_DIR}/${my_patch}"
		done

	fi

	# Make sure our explicit libdir paths don't get clobbered.
	# Gentoo Linux bug #562460
	sed -i \
		-e 's:@bfdlibdir@:@libdir@:g' \
		-e 's:@bfdincludedir@:@includedir@:g' \
		{bfd,opcodes}/Makefile.in || die

	# Fix locale issues if possible
	# Gentoo Linux bug #122216
	if [[ -e ${FILESDIR}/binutils-configure-LANG.patch ]] ; then
		einfo "Fixing misc issues in configure files"
		for f in $(find "${S}" -name configure -exec grep -l 'autoconf version 2.13' {} +) ; do
			ebegin "  Updating ${f/${S}\/}"
			patch "${f}" "${FILESDIR}"/binutils-configure-LANG.patch >& "${T}"/configure-patch.log \
				|| eerror "Please file a bug about this"
			eend $?
		done
	fi

	# Fix conflicts with newer glibc
	# Gentoo Linux bug #272594
	if [[ -e libiberty/testsuite/test-demangle.c ]] ; then
		sed -i 's:\<getline\>:get_line:g' libiberty/testsuite/test-demangle.c
	fi

	# apply any user patches
	eapply_user

	# Run misc portage update scripts
	gnuconfig_update
	elibtoolize --portage --no-uclibc
}

src_configure() {

	# Setup some paths
	LIBPATH=/usr/$(get_libdir)/binutils/${CTARGET}/${PV}
	INCPATH=${LIBPATH}/include
	DATAPATH=/usr/share/binutils-data/${CTARGET}/${PV}
	if is_cross ; then
		TOOLPATH=/usr/${CHOST}/${CTARGET}
	else
		TOOLPATH=/usr/${CTARGET}
	fi
	BINPATH=${TOOLPATH}/binutils-bin/${PV}

	# Make sure we filter $LINGUAS so that only ones that
	# actually work make it through #42033
	strip-linguas -u */po

	# Keep things sane
	strip-flags

	if use elibc_musl; then
		append-ldflags "-Wl,-z,stack-size=2097152"
	fi

	local x
	echo
	for x in CATEGORY CBUILD CHOST CTARGET CFLAGS LDFLAGS ; do
		einfo "$(printf '%10s' ${x}:) ${!x}"
	done
	echo

	install -d "${WORKDIR}"/build
	cd "${WORKDIR}"/build

	local binutils_conf

	if use plugins ; then
		binutils_conf+=( --enable-plugins )
	fi
	# enable gold (installed as ld.gold) and ld's plugin architecture
	if use gold ; then
		binutils_conf+=( --enable-gold )
		if use default-gold; then
			binutils_conf+=( --enable-gold=default )
		fi
	fi

	if use nls ; then
		binutils_conf+=( --without-included-gettext )
	else
		binutils_conf+=( --disable-nls )
	fi

	binutils_conf+=( --with-system-zlib )

	# For bi-arch systems, enable a 64bit bfd.  This matches
	# the bi-arch logic in toolchain.eclass. #446946
	# We used to do it for everyone, but it's slow on 32bit arches. #438522
	case $(tc-arch) in
		ppc|sparc|x86) binutils_conf+=( --enable-64-bit-bfd ) ;;
	esac

	use multitarget && binutils_conf+=( --enable-targets=all --enable-64-bit-bfd )

	[[ -n ${CBUILD} ]] && binutils_conf+=( --build=${CBUILD} )

	is_cross && binutils_conf+=(
		--with-sysroot="${EPREFIX}"/usr/${CTARGET}
		--enable-poison-system-directories
	)

	# glibc-2.3.6 lacks support for this ... so rather than force glibc-2.5+
	# on everyone in alpha (for now), we'll just enable it when possible
	has_version ">=${CATEGORY}/glibc-2.5" && binutils_conf+=( --enable-secureplt )
	has_version ">=sys-libs/glibc-2.5" && binutils_conf+=( --enable-secureplt )

	# mips can't do hash-style=gnu ...
	if [[ $(tc-arch) != mips ]] ; then
		binutils_conf+=( --enable-default-hash-style=gnu )
	fi

	# apply branding
	binutils_conf+=(
	    --with-pkgversion="${BINUTILS_BRANDING}"
	    --with-bugurl="https://bugs.cairnlinux.org"
	)

	# configure paths
	binutils_conf+=(
		--prefix="${EPREFIX}"/usr
		--datadir="${EPREFIX}"${DATAPATH}
		--datarootdir="${EPREFIX}"${DATAPATH}
		--infodir="${EPREFIX}"${DATAPATH}/info
		--mandir="${EPREFIX}"${DATAPATH}/man
		--bindir="${EPREFIX}"${BINPATH}
		--libdir="${EPREFIX}"${LIBPATH}
		--libexecdir="${EPREFIX}"${LIBPATH}
		--includedir="${EPREFIX}"${INCPATH}
	)

	# general
	binutils_conf+=(
		--enable-obsolete
		--enable-shared
		--enable-threads
	)

	# Disable modules that are in a combined binutils/gdb tree
	# Gentoo Linux bug #490566
	binutils_conf+=(
	    --disable-gdb
	    --disable-libdecnumber
	    --disable-readline
	    --disable-sim
	)

	# Pass any local EXTRA_ECONF from /etc/portage/env to ./configure.
	binutils_conf+=( "$@" ${EXTRA_ECONF} )

	binutils_conf+=(
		--host=${CHOST}
		--target=${CTARGET}
		# Newer versions (>=2.27) offer a configure flag now.
		--enable-relro
		# Newer versions (>=2.24) make this an explicit option. #497268
		--enable-install-libiberty
		# Available from 2.35 on
		--enable-textrel-check=warning
		--disable-werror
		# Allow user to opt into CET for host libraries.
		# Ideally automagic-or-disabled here, but the check does not quite work on i686:
		# Gentoo Linux bug #760926.
		$(use_enable cet)
		$(use_enable gas)
		$(use_enable ld)
		$(use_enable static-libs static)
		# Strip out broken static link flags.
		# https://gcc.gnu.org/PR56750
		--without-stage1-ldflags
		# Change SONAME to avoid conflict across
		# {native,cross}/binutils, binutils-libs. #666100
		--with-extra-soversion-suffix=gentoo-${CATEGORY}-${PN}-$(usex multitarget mt st)
	)

	# print out configure opts
	echo ./configure "${binutils_conf[@]}"

	# do configure
	../${PN}-${BINUTILS_VER}/configure "${binutils_conf[@]}" || die "failed to configure binutils"

        # Prevent makeinfo from running if doc is unset.
        if ! use doc ; then
                sed -i \
                        -e '/^MAKEINFO/s:=.*:= true:' \
                        Makefile || die
        fi

	if use bpf; then
		install -d "${WORKDIR}"/build-bpf
		cd "${WORKDIR}"/build-bpf

		local binutils_bpf_conf

		BPF_TARGET="bpf-unknown-none"

		binutils_bpf_conf=(
			--prefix="${EPREFIX}"/usr
			--datadir="${EPREFIX}"/usr/share/binutils-data/${BPF_TARGET}/${PV}
			--datarootdir="${EPREFIX}"/usr/share/binutils-data/${BPF_TARGET}/${PV}
			--infodir="${EPREFIX}"/usr/share/binutils-data/${BPF_TARGET}/${PV}/info
			--mandir="${EPREFIX}"/usr/share/binutils-data/${BPF_TARGET}/${PV}/man
			--bindir="${EPREFIX}"/usr/${BPF_TARGET}/binutils-bin/${PV}
			--libdir="${EPREFIX}"/usr/$(get_libdir)/binutils/${BPF_TARGET}/${PV}
			--libexecdir="${EPREFIX}"/usr/$(get_libdir)/binutils/${BPF_TARGET}/${PV}
			--includedir="${EPREFIX}"/usr/$(get_libdir)/binutils/${BPF_TARGET}/${PV}/include

			--host=${CHOST}
			--target=bpf
			--disable-werror
			--disable-nls
			--enable-plugins
			--with-system-zlib
		)

		# print out configure opts
		echo ./configure "${binutils_bpf_conf[@]}"

	        # do configure
	        ../${PN}-${BINUTILS_VER}/configure "${binutils_bpf_conf[@]}" || die "failed to configure binutils-bpf"

		# Prevent makeinfo from running if doc is unset.
		if ! use doc ; then
			sed -i \
				-e '/^MAKEINFO/s:=.*:= true:' \
				Makefile || die
		fi
	fi
}

src_compile() {

	cd "${WORKDIR}"/build
	# see Note [tooldir hack for ldscripts]
	emake tooldir="${EPREFIX}${TOOLPATH}" all

	# only build info pages if the user wants them
	if use doc ; then
		emake info
	fi

        # we nuke the manpages when we're left with junk
        # (like when we bootstrap, no perl -> no manpages)
        find . -name '*.1' -a -size 0 -delete

	if use bpf; then
		cd "${WORKDIR}"/build-bpf

	        # see Note [tooldir hack for ldscripts]
	        emake tooldir="${EPREFIX}/usr/${BPF_TARGET}" all

	        # only build info pages if the user wants them
	        if use doc ; then
	                emake info
	        fi

	        # we nuke the manpages when we're left with junk
	        # (like when we bootstrap, no perl -> no manpages)
	        find . -name '*.1' -a -size 0 -delete
	fi
}

src_test() {
	cd "${WORKDIR}"/build

	# bug 637066
	filter-flags -Wall -Wreturn-type

	emake -k check

	if use bpf; then
	        # bug 637066
	        filter-flags -Wall -Wreturn-type

	        emake -k check
	fi
}

src_install() {

	cd "${WORKDIR}"/build

	local x d

	# see Note [tooldir hack for ldscripts]
	emake DESTDIR="${D}" tooldir="${EPREFIX}${LIBPATH}" install
	rm -rf "${ED}"/${LIBPATH}/bin
	use static-libs || find "${ED}" -name '*.la' -delete

	# Newer versions of binutils get fancy with ${LIBPATH} #171905
	cd "${ED}"/${LIBPATH}
	for d in ../* ; do
		[[ ${d} == ../${PV} ]] && continue
		mv ${d}/* . || die
		rmdir ${d} || die
	done

	# Now we collect everything intp the proper SLOT-ed dirs
	# When something is built to cross-compile, it installs into
	# /usr/$CHOST/ by default ... we have to 'fix' that :)
	if is_cross ; then
		cd "${ED}"/${BINPATH}
		for x in * ; do
			mv ${x} ${x/${CTARGET}-}
		done

		if [[ -d ${ED}/usr/${CHOST}/${CTARGET} ]] ; then
			mv "${ED}"/usr/${CHOST}/${CTARGET}/include "${ED}"/${INCPATH}
			mv "${ED}"/usr/${CHOST}/${CTARGET}/lib/* "${ED}"/${LIBPATH}/
			rm -r "${ED}"/usr/${CHOST}/{include,lib}
		fi
	fi
	insinto ${INCPATH}
	local libiberty_headers=(
		# Not all the libiberty headers.  See libiberty/Makefile.in:install_to_libdir.
		demangle.h
		dyn-string.h
		fibheap.h
		hashtab.h
		libiberty.h
		objalloc.h
		splay-tree.h
	)
	doins "${libiberty_headers[@]/#/${S}/include/}"
	if [[ -d ${ED}/${LIBPATH}/lib ]] ; then
		mv "${ED}"/${LIBPATH}/lib/* "${ED}"/${LIBPATH}/
		rm -r "${ED}"/${LIBPATH}/lib
	fi

	# Generate an env.d entry for this binutils
	local target_lib_paths=( ${EPREFIX}${LIBPATH} )
	use bpf && target_lib_paths+=( ${EPREFIX}/usr/$(get_libdir)/binutils/${BPF_TARGET}/${PV} )
	insinto /etc/env.d/binutils
	cat <<-EOF > "${T}"/env.d
		TARGET="${CTARGET}"
		VER="${PV}"
		LIBPATH="${target_lib_paths"
	EOF
	newins "${T}"/env.d ${CTARGET}-${PV}

	# Handle documentation
	if ! is_cross ; then
		cd "${S}"
		dodoc README
		docinto bfd
		dodoc bfd/ChangeLog* bfd/README bfd/PORTING bfd/TODO
		docinto binutils
		dodoc binutils/ChangeLog binutils/NEWS binutils/README
		docinto gas
		dodoc gas/ChangeLog* gas/CONTRIBUTORS gas/NEWS gas/README*
		docinto gprof
		dodoc gprof/ChangeLog* gprof/TEST gprof/TODO gprof/bbconv.pl
		docinto ld
		dodoc ld/ChangeLog* ld/README ld/NEWS ld/TODO
		docinto libiberty
		dodoc libiberty/ChangeLog* libiberty/README
		docinto opcodes
		dodoc opcodes/ChangeLog*
	fi

	# Remove shared info pages
	rm -f "${ED}"/${DATAPATH}/info/{dir,configure.info,standards.info}

	# Trim all empty dirs
	find "${ED}" -depth -type d -exec rmdir {} + 2>/dev/null

	if use bpf; then
		cd "${WORKDIR}"/build-bpf

		local x d

		# see Note [tooldir hack for ldscripts]
		emake DESTDIR="${D}" tooldir="${EPREFIX}"/usr/$(get_libdir)/binutils/${BPF_TARGET}/${PV} install

		echo ${DESTDIR}
		echo ${tooldir}

		rm -rf "${ED}"/usr/$(get_libdir)/binutils/${BPF_TARGET}/${PV}/bin
		use static-libs || find "${ED}" -name '*.la' -delete

		# Newer versions of binutils get fancy with ${LIBPATH} #171905
		cd "${ED}"/usr/$(get_libdir)/binutils/${BPF_TARGET}/${PV}
		for d in ../* ; do
			[[ ${d} == ../${PV} ]] && continue
			mv ${d}/* . || die
			rmdir ${d} || die
		done

		# Now we collect everything intp the proper SLOT-ed dirs
		# When something is built to cross-compile, it installs into
		# /usr/$CHOST/ by default ... we have to 'fix' that :)
		if is_cross ; then
			cd "${ED}"/${BINPATH}
			for x in * ; do
				mv ${x} ${x/${CTARGET}-}
			done

			if [[ -d ${ED}/usr/${CHOST}/${CTARGET} ]] ; then
				mv "${ED}"/usr/${CHOST}/${CTARGET}/include "${ED}"/${INCPATH}
				mv "${ED}"/usr/${CHOST}/${CTARGET}/lib/* "${ED}"/${LIBPATH}/
				rm -r "${ED}"/usr/${CHOST}/{include,lib}
			fi
		fi
		insinto /usr/$(get_libdir)/binutils/${BPF_TARGET}/${PV}/include
		local libiberty_headers=(
			# Not all the libiberty headers.  See libiberty/Makefile.in:install_to_libdir.
			demangle.h
			dyn-string.h
			fibheap.h
			hashtab.h
			libiberty.h
			objalloc.h
			splay-tree.h
		)
		doins "${libiberty_headers[@]/#/${S}/include/}"
		if [[ -d ${ED}/usr/$(get_libdir)/binutils/${BPF_TARGET}/${PV}/lib ]] ; then
			mv "${ED}"/usr/$(get_libdir)/binutils/${BPF_TARGET}/${PV}/lib/* "${ED}"/usr/$(get_libdir)/binutils/${BPF_TARGET}/${PV}/
			rm -r "${ED}"/usr/$(get_libdir)/binutils/${BPF_TARGET}/${PV}/lib
		fi

		# Handle documentation
		if ! is_cross ; then
			cd "${S}"
			dodoc README
			docinto bfd
			dodoc bfd/ChangeLog* bfd/README bfd/PORTING bfd/TODO
			docinto binutils
			dodoc binutils/ChangeLog binutils/NEWS binutils/README
			docinto gas
			dodoc gas/ChangeLog* gas/CONTRIBUTORS gas/NEWS gas/README*
			docinto gprof
			dodoc gprof/ChangeLog* gprof/TEST gprof/TODO gprof/bbconv.pl
			docinto ld
			dodoc ld/ChangeLog* ld/README ld/NEWS ld/TODO
			docinto libiberty
			dodoc libiberty/ChangeLog* libiberty/README
			docinto opcodes
			dodoc opcodes/ChangeLog*
		fi

		# Remove shared info pages
		rm -f "${ED}"/usr/share/binutils-data/${BPF_TARGET}/${PV}/info/{dir,configure.info,standards.info}

		# Trim all empty dirs
		find "${ED}" -depth -type d -exec rmdir {} + 2>/dev/null
	fi
}

pkg_postinst() {
	# Make sure this ${CTARGET} has a binutils version selected
	[[ -e ${EROOT}/etc/env.d/binutils/config-${CTARGET} ]] && return 0
	binutils-config ${CTARGET}-${PV}
}

pkg_postrm() {
	local current_profile=$(binutils-config -c ${CTARGET})

	# If no other versions exist, then uninstall for this target ... otherwise, switch to the newest version
	# Note: only do this if this version is unmerged.  We rerun binutils-config if this is a remerge, as
	# we want the mtimes on the symlinks updated (if it is the same as the current selected profile).
	if [[ ! -e ${EPREFIX}${BINPATH}/ld ]] && [[ ${current_profile} == ${CTARGET}-${PV} ]] ; then
		local choice=$(binutils-config -l | grep ${CTARGET} | awk '{print $2}')
		choice=${choice//$'\n'/ }
		choice=${choice/* }
		if [[ -z ${choice} ]] ; then
			binutils-config -u ${CTARGET}
		else
			binutils-config ${choice}
		fi
	elif [[ $(CHOST=${CTARGET} binutils-config -c) == ${CTARGET}-${PV} ]] ; then
		binutils-config ${CTARGET}-${PV}
	fi
}

# Note [slotting support]
# -----------------------
# Gentoo's layout for binutils files is non-standard as Gentoo
# supports slotted installation for binutils. Many tools
# still expect binutils to reside in known locations.
# binutils-config package restores symlinks into known locations,
# like:
#    /usr/bin/${CTARGET}-<tool>
#    /usr/bin/${CHOST}/${CTARGET}/lib/ldscrips
#    /usr/include/
#
# Note [tooldir hack for ldscripts]
# ---------------------------------
# Build system does not allow ./configure to tweak every location
# we need for slotting binutils hence all the shuffling in
# src_install(). This note is about SCRIPTDIR define handling.
#
# SCRIPTDIR defines 'ldscripts/' directory location. SCRIPTDIR value
# is set at build-time in ld/Makefile.am as: 'scriptdir = $(tooldir)/lib'
# and hardcoded as -DSCRIPTDIR='"$(scriptdir)"' at compile time.
# Thus we can't just move files around after compilation finished.
#
# Our goal is the following:
# - at build-time set scriptdir to point to symlinked location:
#   ${TOOLPATH}: /usr/${CHOST} (or /usr/${CHOST}/${CTARGET} for cross-case)
# - at install-time set scriptdir to point to slotted location:
#   ${LIBPATH}: /usr/$(get_libdir)/binutils/${CTARGET}/${PV}
