local version = ZOI.VERSION or "8.23.0"
local sha512 =
	"69cf0feafdc79fbad007cf2fc977b777ce6ccb05d01afd17b5a42f8bedbfcc342fc3a48193faa7f3eafe6800cd7d07948916e8733db1b9de60287ed06219b840"
-- Release signing key (Daniel Stenberg), matches Arch's validpgpkeys.
local signing_key = "27EDEAF22F3ABCEB50DB9A125CC908FDB71E12C2"

metadata({
	name = "curl",
	repo = "core",
	version = version,
	revision = "5",
	debug = { sub_package = true },
	description = "Command line tool and library for transferring data with URLs",
	website = "https://curl.se",
	license = "curl",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Daniel Stenberg and contributors",
		website = "https://curl.se",
	},
	bins = {
		"curl",
		"curl-config",
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
					"pacman:brotli",
					"pacman:ca-certificates",
					"pacman:gcc",
					"pacman:krb5",
					"pacman:libidn2",
					"pacman:libnghttp2",
					"pacman:libnghttp3",
					"pacman:libngtcp2",
					"pacman:libpsl",
					"pacman:libssh2",
					"pacman:make",
					"pacman:openssl",
					"pacman:pkgconf",
					"pacman:zlib",
					"pacman:zstd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/brotli",
			"zoi:@core/ca-certificates",
			"zoi:@core/glibc",
			"zoi:@core/krb5",
			"zoi:@core/libidn2",
			"zoi:@core/libnghttp2",
			"zoi:@core/libnghttp3",
			"zoi:@core/libngtcp2",
			"zoi:@core/libpsl",
			"zoi:@core/libssh2",
			"zoi:@core/openssl",
			"zoi:@core/zlib",
			"zoi:@core/zstd",
		},
	},
})

local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "curl-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://curl.se/download" \
				"https://github.com/curl/curl/releases/download/curl-$(echo "$VER" | tr . _)"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "curl-$VER.tar.xz"
		fetch "curl-$VER.tar.xz.asc"
		echo "$SHA512  curl-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "curl-$VER.tar.xz"]], opts)
end

function build()
	-- Features as Arch's curl: GSS-API (krb5), SCP/SFTP (libssh2) and HTTP/3
	-- (ngtcp2 with its OpenSSL QUIC backend + nghttp3), versioned symbols.
	-- LDAP stays disabled as on Arch. Optional libraries Arch does not use
	-- are disabled explicitly so the build host's copies are never linked.
	cmd(
		[[
		cd "curl-$VER"

		./configure \
			--prefix=/usr \
			--mandir=/usr/share/man \
			--disable-ldap \
			--disable-ldaps \
			--disable-manual \
			--enable-ipv6 \
			--enable-threaded-resolver \
			--enable-websockets \
			--enable-versioned-symbols \
			--disable-ares \
			--with-openssl \
			--without-gnutls \
			--with-gssapi \
			--with-libssh2 \
			--without-libssh \
			--with-nghttp2 \
			--with-nghttp3 \
			--with-ngtcp2 \
			--without-libgsasl \
			--without-libuv \
			--with-brotli \
			--with-zstd \
			--with-zlib \
			--with-libidn2 \
			--with-libpsl \
			--with-ca-bundle=/etc/ssl/certs/ca-certificates.crt

		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "curl-$VER" DESTDIR="$ROOT" install]], opts)
	zlicense("curl-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/curl --version || curl --version || true
	]])
end
