# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit toolchain-funcs

HOMEPAGE="https://github.com/oracle/dtrace-utils"
DESCRIPTION="DTrace userspace utilities"

LICENSE="GPL-2"
KEYWORDS=""

SLOT="0"

IUSE="test"

RDEPEND="
    dev-libs/elfutils
    dev-libs/libdtrace-ctf
    sys-libs/zlib
"

DEPEND="
    sys-devel/bison
    sys-devel/binutils[multitarget]
    sys-devel/clang
    sys-devel/flex
    dev-libs/libbpf
    net-libs/libpcap
    virtual/os-headers
"

DTRACE_UTILS_VER="2.0.0"
DTRACE_UTILS_REV="1.2"
DTRACE_UTILS_ARCHIVE="${DTRACE_UTILS_VER}-${DTRACE_UTILS_REV}.tar.gz"

SRC_URI="https://github.com/oracle/dtrace-utils/archive/${DTRACE_UTILS_ARCHIVE}"

BPF_HEADERS=(
    bpf.h
    bpf_core_read.h
    bpf_endian.h
    bpf_helper_defs.h
    bpf_helpers.h
    bpf_tracing.h
    btf.h
    libbpf.h
    libbpf_common.h
    libbpf_util.h
    xsk.h
)

pkg_setup() {

        for files_to_symlink in ${BPF_HEADERS[*]} ; do
            if [[ ! -h "${EROOT}"/usr/include/"${files_to_symlink}" ]]; then
                ln -s ${EROOT}/usr/include/bpf/"${files_to_symlink}" ${EROOT}/usr/include/"${files_to_symlink}"
            fi
        done
}

src_unpack() {

    # unpack sources
    unpack ${DTRACE_UTILS_ARCHIVE} && mv ${WORKDIR}/${PN}-${DTRACE_UTILS_VER}-${DTRACE_UTILS_REV} ${WORKDIR}/${PN}-${DTRACE_UTILS_VER} || die "failed to unpack archive"
}

src_prepare() {

    # punt unless USE=test
    if ! use test; then
        rm -rf test
    fi

    eapply ${FILESDIR}/fix-double-declaration-of-yylineno.patch || die "patch failed"

    # upstream depends on bpf-helpers.h from gcc... which isn't very portable (and is scheduled for removal).
    # libbpf ships bpf_helpers.h etc... so we sed that change across the source files.
    find . -type f -exec sed -i -e 's/bpf-helpers.h/bpf_helpers.h/g' {} \; || die "bpf-helpers.h sed failed"

    # apply any user patches
    eapply_user
}

src_configure() {

    # create the build directory
    mkdir "${WORKDIR}"/build

    # DTrace-utils requires a bpf target enabled compiler.
    # Both gcc and clang support this, however gcc requires it be setup as an additional cross-compiler...
    # whereas clang supports this natively, with no additional cross-compilers required.
    #
    # I can't really be bothered to create minimal gcc-bpf and binutils-bpf packages,
    # nor do I think it is a good idea to depend on crossdev for this dependency.
    # So for now we shall use clang...
    MAKEARGS=(
        BPFC="${CHOST}-clang"
        BPFLD="$(tc-getLD)"
    )
}

src_compile() {

    emake O="${WORKDIR}"/build "${MAKEARGS[@]}" all || "build failed"
}

pkg_postrm() {

    for symlinks_to_remove in ${BPF_HEADERS[*]} ; do
        if [[ -h "${EROOT}"/usr/include/"${symlinks_to_remove}" ]]; then
            rm -rf "${EROOT}"/usr/include/"${symlinks_to_remove}"
        fi
    done
}
