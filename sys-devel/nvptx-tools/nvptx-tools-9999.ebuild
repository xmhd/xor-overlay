# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools multilib-minimal

DESCRIPTION="a collection of tools for use with nvptx-none GCC toolchains"
HOMEPAGE="https://github.com/MentorEmbedded/nvptx-tools"
SRC_URI=""

LICENSE="GPL-3"
KEYWORDS=""

SLOT="0"

DEPEND="
	x11-drivers/nvidia-drivers
	dev-util/nvidia-cuda-toolkit
"

src_prepare() {

	eapply "${FILESDIR}"/${PN}-no-error-as-needed.patch

	multilib_copy_sources

	# apply user patches
	eapply_user
}

multilib_src_configure() {

	conf_nvptx=(
		--target="nvptx-none"
		--with-cuda-driver="/opt/cuda"
	)

	econf ${conf_nvptx[@]} || die "failed to configure nvptx-tools"
}
