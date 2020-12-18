# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Hardened memory allocator designed for modern systems."
HOMEPAGE="https://github.com/GrapheneOS/hardened_malloc"

LICENSE="GPL-2"
KEYWORDS="amd64 arm64"

SLOT="0"

IUSE="custom-cflags debug sanitize test"

DEPEND="
    elibc_glibc? ( >=sys-libs/glibc-2.28 )
    elibc_musl? ( >=sys-libs/musl-1.1.20 )
"

if [[ ${PV} == 9999* ]]; then
    inherit git-r3
    EGIT_REPO_URI="https://github.com/GrapheneOS/hardened_malloc.git"
else
    SRC_URI="${HOMEPAGE}/archive/${PV}.tar.gz -> ${PN}-${PV}.tar.gz"
fi

src_unpack() {

    # unpack git sources...
    if [[ ${PV} == 9999* ]]; then
        git-r3_src_unpack
    else
        # ... or unpack downloaded sources
        default
    fi
}

src_prepare() {

    # punt tests unless we want them
    if ! use test; then
        rm -rf "${S}/test" || die "failed to remove test directory"
    fi

    # apply any user patches
    eapply_user
}

src_configure() {
    MAKEARGS=(
        CONFIG_WERROR=true
        $(usex custom-cflags CONFIG_NATIVE=true CONFIG_NATIVE=false)
        CONFIG_CXX_ALLOCATOR=true
        $(usex sanitize CONFIG_UBSAN=true CONFIG_UBSAN=false)
        CONFIG_ZERO_ON_FREE=true
        CONFIG_WRITE_AFTER_FREE_CHECK=true
        CONFIG_SLOT_RANDOMIZE=true
        CONFIG_SLAB_CANARY=true
        CONFIG_SEAL_METADATA=false
        CONFIG_SLAB_QUARANTINE_RANDOM_LENGTH=1
        CONFIG_SLAB_QUARANTINE_QUEUE_LENGTH=1
        CONFIG_GUARD_SLABS_INTERVAL=1
        CONFIG_GUARD_SIZE_DIVISOR=2
        CONFIG_REGION_QUARANTINE_RANDOM_LENGTH=128
        CONFIG_REGION_QUARANTINE_QUEUE_LENGTH=1024
        CONFIG_REGION_QUARANTINE_SKIP_THRESHOLD=33554432
        CONFIG_FREE_SLABS_QUARANTINE_RANDOM_LENGTH=32
        CONFIG_CLASS_REGION_SIZE=34359738368
        CONFIG_N_ARENA=4
        $(usex debug CONFIG_STATS=true CONFIG_STATS=false)
        CONFIG_EXTENDED_SIZE_CLASSES=true
        CONFIG_LARGE_SIZE_CLASSES=true
    )

    mkdir build || die "failed to create build directory"
}

src_compile() {
    emake O="${WORKDIR}"/build "${MAKEARGS[@]}" || "hardened_malloc build failed"
}

src_install() {

    # install libhardened_malloc.so to /usr/lib
    insinto /usr/lib64 && doins "libhardened_malloc.so"
    fperms 755 /usr/lib64/libhardened_malloc.so || die "failed to set permissions for libhardened_malloc.so"

    # install preload.sh to /usr/bin
    # install calculate_waste.py to /usr/bin
    insinto /usr/bin && doins "preload.sh" || die "failed to install preload.sh"
    insinto /usr/bin && doins "calculate_waste.py" || die "failed to install calculate_waste.py"
    fperms 755 /usr/bin/{preload.sh,calculate_waste.py} || die "failed to set permissions for preload.sh and calculate_waste.py"

    # raise vm.max_map_count substantially too to accomodate the very large number of guard pages created by hardened_malloc
    echo "vm.max_map_count = 524240" >> "${ED}"/etc/sysctl.d/40-hardened-malloc.conf

    if use default_malloc; then
        # add libhardened_malloc.so to ld.so.preload
        echo "/usr/lib64/libhardened_malloc.so" >> "${ED}"/etc/ld.so.preload
    fi
}
