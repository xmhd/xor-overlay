#!/bin/bash

if [[ $# -ne 1 ]] ; then
	echo "Usage: $0 <gcc ebuild>"
	exit 1
fi

ver=${1%/}
for ebuild in \
	${ver} \
	/usr/local/src/gentoo/repo/gentoo/sys-devel/gcc/gcc-${ver}.ebuild \
	"$(portageq get_repo_path $(portageq envvar EPREFIX)/ gentoo)"/sys-devel/gcc/gcc-${ver}.ebuild \
	/usr/portage/sys-devel/gcc/gcc-${ver}.ebuild \
	""
do
	[[ -f ${ebuild} ]] && break
done
if [[ -z ${ebuild} ]] ; then
	echo "!!! gcc ebuild '${ver}' does not exist"
	exit 1
fi

digest=${ebuild/.ebuild}
rm -f ${digest/gcc\//gcc\/files\/digest-}
gver=${ebuild##*/gcc/gcc-} # trim leading path
gver=${gver%%.ebuild}      # trim post .ebuild
gver=${gver%%-*}           # trim any -r#'s
gver=${gver%%_pre*}        # trim any _pre.*#'s

# trim branch update number
sgver=$(echo ${gver} | sed -e 's:[0-9]::g')
[[ ${#sgver} -gt 2 ]] \
	&& sgver=${gver%.*} \
	|| sgver=${gver}

eread() {
	inherit(){ :;}
	while [[ $# -gt 0 ]] ; do
		export $1=$(source ${ebuild} 2>/dev/null; echo ${!1})
		shift
	done
}
eread UCLIBC_VER PP_VER HTB_VER HTB_GCC_VER MAN_VER SPECS_VER SPECS_GCC_VER
[[ -n ${HTB_VER} && -z ${HTB_GCC_VER} ]] && HTB_GCC_VER=${gver}
PATCH_VER=$(awk '{print $1; exit}' ./${gver}/gentoo/README.history)
PIE_VER=$(awk '{print $1; exit}' ./${gver}/pie/README.history)

if [[ ! -d ./${gver} ]] ; then
	echo "Error: ${gver} is not a valid gcc ver"
	exit 1
fi

echo "Building patches for gcc version ${gver}"
echo " - PATCH:    ${PATCH_VER} (taken from ${gver}/gentoo/README.history)"
echo " - UCLIBC:   ${UCLIBC_VER}"
echo " - PIE:      ${PIE_VER} (taken from ${gver}/pie/README.history)"
echo " - SPECS:    ${SPECS_VER} (${SPECS_GCC_VER:-${gver}})"
echo " - SSP:      ${PP_VER}"
echo " - BOUNDS:   ${HTB_GCC_VER}-${HTB_VER}"
echo " - MAN:      ${MAN_VER}"

rm -rf tmp
rm -f gcc-${gver}-*.tar.bz2

# standard jobbies
mkdir -p tmp/patch/exclude tmp/uclibc tmp/piepatch tmp/specs
[[ -n ${PATCH_VER}  ]] && cp ${gver}/gentoo/*.patch ${gver}/gentoo/README.history README.Gentoo.patches tmp/patch/
[[ -d ${gver}/man   ]] && cp -r ${gver}/man tmp/
[[ -n ${UCLIBC_VER} ]] && cp -r ${gver}/uclibc/* README.Gentoo.patches tmp/uclibc/
[[ -n ${PIE_VER}    ]] && cp -r ${gver}/pie/* README.Gentoo.patches tmp/piepatch/
[[ -n ${PP_VER}     ]] && cp -r ${gver}/ssp tmp/
[[ -n ${SPECS_VER}  ]] && cp -r ${SPECS_GCC_VER:-${gver}}/specs/* tmp/specs/
# extra cruft
[[ -n ${HTB_VER} ]] && \
cp ${gver}/misc/bounds-checking-gcc*.patch \
   tmp/bounds-checking-gcc-${HTB_GCC_VER}-${HTB_VER}.patch
find tmp/ -name CVS -type d | xargs rm -rf

# standard jobbies
[[ -n ${PATCH_VER}  ]] && {
tar -jcf gcc-${sgver}-patches-${PATCH_VER}.tar.bz2 \
	-C tmp patch || exit 1 ; }
[[ -n ${UCLIBC_VER} ]] && {
tar -jcf gcc-${sgver}-uclibc-patches-${UCLIBC_VER}.tar.bz2 \
	-C tmp uclibc || exit 1 ; }
[[ -n ${PIE_VER}    ]] && {
tar -jcf gcc-${sgver}-piepatches-v${PIE_VER}.tar.bz2 \
	-C tmp piepatch || exit 1 ; }
[[ -n ${SPECS_VER}  ]] && {
tar -jcf gcc-${sgver}-specs-${SPECS_VER}.tar.bz2 \
	-C tmp specs || exit 1 ; }
[[ -n ${PP_VER}     ]] && {
mv tmp/ssp/protector.patch tmp/ssp/gcc-${gver}-ssp.patch
tar -jcf gcc-${gver}-ssp-${PP_VER}.tar.bz2 \
	-C tmp ssp || exit 1 ; }
[[ -d ${gver}/man   ]] && {
tar -jcf gcc-${MAN_VER}-manpages.tar.bz2 \
	-C tmp/man . || exit 1 ; }
# extra cruft
[[ -n ${HTB_VER}    ]] && {
bzip2 tmp/bounds-checking-*.patch \
	&& cp tmp/bounds-checking-*.patch.bz2 . || exit 1 ; }
rm -rf tmp

du -b *.bz2
