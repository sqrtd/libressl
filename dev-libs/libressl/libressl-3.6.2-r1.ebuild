# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools multilib-minimal verify-sig

DESCRIPTION="Free version of the SSL/TLS protocol forked from OpenSSL"
HOMEPAGE="https://www.libressl.org/"
SRC_URI="
	https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/${P}.tar.gz
	verify-sig? ( https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/${P}.tar.gz.asc )
"

LICENSE="ISC openssl"
# Reflects ABI of libcrypto.so and libssl.so. Since these can differ,
# we'll try to use the max of either. However, if either change between
# versions, we have to change the subslot to trigger rebuild of consumers.
SLOT="0/53"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~loong ~mips ~ppc ~ppc64 ~s390 ~sparc x86 ~amd64-linux ~ppc-macos ~x64-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="+asm static-libs test"
RESTRICT="!test? ( test )"

PDEPEND="app-misc/ca-certificates"
BDEPEND="verify-sig? ( sec-keys/openpgp-keys-libressl )"

VERIFY_SIG_OPENPGP_KEY_PATH="${BROOT}"/usr/share/openpgp-keys/libressl.asc

PATCHES=(
	"${FILESDIR}"/${PN}-2.8.3-solaris10.patch
	# Gentoo's ssl-cert.eclass uses 'openssl genrsa -rand'
	# which LibreSSL doesn't support.
	# https://github.com/libressl/portable/issues/839
	"${FILESDIR}"/${PN}-3.6.2-genrsa-rand.patch
	# https://github.com/libressl-portable/portable/pull/806
	"${FILESDIR}"/${PN}-3.7.0-no-static-tests.patch
)

src_prepare() {
	default

	# Required for the no-static-tests.patch
	touch tests/empty.c || die

	eautoreconf
}

multilib_src_configure() {
	local ECONF_SOURCE="${S}"
	local args=(
		$(use_enable asm)
		$(use_enable static-libs static)
		$(use_enable test tests)
	)
	econf "${args[@]}"
}

multilib_src_install_all() {
	einstalldocs
	find "${D}" -name '*.la' -exec rm -f {} + || die
}
