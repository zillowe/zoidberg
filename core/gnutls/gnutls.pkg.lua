local version = ZOI.VERSION or "3.8.14"
local sha512 = "d28911cb6176ada9d90e5611f065d8a56744cc63771ca73a0544f4cf07eb4e33c6c07debd3ef471ffe8fa0fbf327ff8393a998c95c64ddae788514adc5d8f266"
-- Release signing key (Alexander Sosedkin), matches Arch Linux's
-- validpgpkeys. Releases are signed by its subkey
-- A6AB53A01D237A94F9EEC4D0412748A40AFCC2FB.
local signing_key = "E987AB7F7E89667776D05B3BB0E9DD20B29F1432"

metadata({
	name = "gnutls",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "A library which provides a secure layer over a reliable transport layer",
	website = "https://www.gnutls.org/",
	license = "GPL-3.0-or-later AND LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The GnuTLS Project",
		website = "https://www.gnutls.org",
	},
	bins = {
		"certtool",
		"gnutls-cli",
		"gnutls-cli-debug",
		"gnutls-serv",
		"ocsptool",
		"p11tool",
		"psktool",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/gnutls/config",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:base-devel",
					"pacman:brotli",
					"pacman:curl",
					"pacman:gcc",
					"pacman:gmp",
					"pacman:libidn2",
					"pacman:libtasn1",
					"pacman:libunistring",
					"pacman:make",
					"pacman:nettle",
					"pacman:p11-kit",
					"pacman:pkgconf",
					"pacman:tar",
					"pacman:tpm2-tss",
					"pacman:xz",
					"pacman:zlib",
					"pacman:zstd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/brotli",
			"zoi:@core/gcc:libgcc",
			"zoi:@core/gcc:libstdc++",
			"zoi:@core/glibc",
			"zoi:@core/gmp",
			"zoi:@core/libidn2",
			"zoi:@core/libtasn1",
			"zoi:@core/libunistring",
			"zoi:@core/nettle",
			"zoi:@core/p11-kit",
			"zoi:@core/zlib",
			"zoi:@core/zstd",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = {
	check = true,
	env = { VER = version, SHA512 = sha512, SERIES = version:match("^(%d+%.%d+)") },
}

function prepare()
	local tarball = "gnutls-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.gnupg.org/ftp/gcrypt/gnutls/v$SERIES" \
				"https://gnupg.org/ftp/gcrypt/gnutls/v$SERIES"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "gnutls-$VER.tar.xz"
		fetch "gnutls-$VER.tar.xz.sig"
		echo "$SHA512  gnutls-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "gnutls-$VER.tar.xz"]], opts)
end

function build()
	-- Options follow Arch Linux, except:
	-- - no --with-leancrypto: leancrypto is not packaged in Zoidberg.
	-- - libdane (needs unbound) and TPM 1.2 (trousers) are disabled
	--   explicitly so the build host's libraries are never picked up; Arch
	--   builds without them as well.
	-- zlib, brotli, zstd and tpm2-tss are dlopen()ed at runtime. tpm2-tss
	-- is not in Zoidberg, so TPM2 wrapped keys stay unavailable until it is.
	cmd(
		[[
		cd "gnutls-$VER"
		./configure \
			--prefix=/usr \
			--sysconfdir=/etc \
			--disable-static \
			--with-idn \
			--with-brotli \
			--with-zstd \
			--with-tpm2 \
			--without-tpm \
			--disable-libdane \
			--enable-openssl-compatibility \
			--with-default-trust-store-pkcs11="pkcs11:" \
			--enable-ktls
		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "gnutls-$VER"
		make DESTDIR="$ROOT" install

		# KTLS is built in but disabled by default (as on Arch).
		install -Dm644 "$PKGLUADIR/files/config" "$ROOT/etc/gnutls/config"
	]],
		opts
	)

	zlicense("gnutls-" .. version .. "/COPYING")
	zlicense("gnutls-" .. version .. "/COPYING.LESSERv2")
end
