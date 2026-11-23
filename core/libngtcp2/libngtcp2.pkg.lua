local version = ZOI.VERSION or "1.26.0"
local sha512 = "3f4ecf8720d3b43034b120111e804e453044d159fe1a69134a599260be80f6c600810679b2d285c271321e9e88b3ce127c6793d5c142a746278038d807208bbf"
-- Upstream signs releases (subkey 516B622918D15C478AB1EA3A5339A2BE82E07DEC of
-- key F4F3B91474D1EB29889BD0EF7E8403D5D673C366, Tatsuhiro Tsujikawa, Arch's
-- validpgpkeys), but the subkey is only bound with a SHA-1 signature, which
-- Zoi's verifier rejects. The signature was checked with gpg when this hash
-- was recorded, and the hash matches Gentoo's Manifest; the pinned hash is
-- the trust anchor.

metadata({
	name = "libngtcp2",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Implementation of IETF QUIC protocol",
	website = "https://github.com/ngtcp2/ngtcp2",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The ngtcp2 project",
		website = "https://nghttp2.org/ngtcp2/",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
					"pacman:openssl",
					"pacman:pkgconf",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/openssl",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors \
			"https://github.com/ngtcp2/ngtcp2/releases/download/v$VER/ngtcp2-$VER.tar.xz" \
			-o "ngtcp2-$VER.tar.xz"
		echo "$SHA512  ngtcp2-$VER.tar.xz" | sha512sum -c -
		tar -xf "ngtcp2-$VER.tar.xz"
	]],
		opts
	)
end

function build()
	-- Crypto backend: OpenSSL only (libngtcp2_crypto_ossl, using the QUIC API
	-- of OpenSSL >= 3.5; Zoidberg ships 4.x). This is the backend curl uses.
	-- Arch additionally builds the GnuTLS backend; nothing in Zoidberg needs
	-- it, so it is disabled explicitly, as are the other TLS stacks so the
	-- build host's copies are never picked up. Brotli is only used by the
	-- examples, which --enable-lib-only (as on Arch) does not build.
	cmd(
		[[
		cd "ngtcp2-$VER"
		./configure \
			--prefix=/usr \
			--disable-static \
			--enable-lib-only \
			--with-openssl \
			--without-gnutls \
			--without-boringssl \
			--without-picotls \
			--without-wolfssl \
			--without-jemalloc
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "ngtcp2-$VER" DESTDIR="$ROOT" install]], opts)
	zlicense("ngtcp2-" .. version .. "/COPYING")
end
