local version = ZOI.VERSION or "3.8.11"
local sha512 = "7e9145c51d389ae5fa4e64c9a791dcbe4960ae064ebefa40d73d6079180af17795d7d0f9dffc939f9d050b9be2669f45115bb89a9466f43617e731edab57ccf1"
-- Release signing key (Martin Matuska <mm@FreeBSD.org>), one of the two
-- keys in Arch Linux's validpgpkeys. The hash is Gentoo's
-- (app-arch/libarchive Manifest).
local signing_key = "659C84C0E23EA1FA97E0B58CC040B508D63D2B36"

metadata({
	name = "libarchive",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Multi-format archive and compression library",
	website = "https://libarchive.org/",
	license = "BSD-2-Clause AND BSD-4-Clause-UC AND (Apache-2.0 OR CC0-1.0 OR OpenSSL)",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The libarchive developers",
		website = "https://github.com/libarchive/libarchive",
	},
	bins = { "bsdcat", "bsdcpio", "bsdtar", "bsdunzip" },
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
					"pacman:acl",
					"pacman:bzip2",
					"pacman:curl",
					"pacman:gcc",
					"pacman:libxml2",
					"pacman:lz4",
					"pacman:make",
					"pacman:openssl",
					"pacman:pkgconf",
					"pacman:tar",
					"pacman:xz",
					"pacman:zlib",
					"pacman:zstd",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/acl",
			"zoi:@core/bzip2",
			"zoi:@core/glibc",
			"zoi:@core/libxml2",
			"zoi:@core/lz4",
			"zoi:@core/openssl",
			"zoi:@core/xz",
			"zoi:@core/zlib",
			"zoi:@core/zstd",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libarchive-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/libarchive/libarchive/releases/download/v$VER" \
				"https://libarchive.org/downloads"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libarchive-$VER.tar.xz"
		fetch "libarchive-$VER.tar.xz.asc"
		echo "$SHA512  libarchive-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "libarchive-$VER.tar.xz"]], opts)
end

function build()
	-- Arch's options (--without-nettle --disable-static). Every optional
	-- library is chosen explicitly so the build host's extra libraries
	-- (libb2, lzo, mbedtls, expat …) are never picked up: only those in the
	-- runtime dependencies above are linked.
	cmd(
		[[
		cd "libarchive-$VER"
		./configure \
			--prefix=/usr \
			--disable-static \
			--enable-acl \
			--enable-xattr \
			--enable-posix-regex-lib=libc \
			--with-zlib \
			--with-bz2lib \
			--with-lzma \
			--with-lz4 \
			--with-zstd \
			--with-openssl \
			--with-xml2 \
			--with-iconv \
			--without-libb2 \
			--without-lzo2 \
			--without-mbedtls \
			--without-nettle \
			--without-expat
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "libarchive-$VER" DESTDIR="$ROOT" install]], opts)
	zlicense("libarchive-" .. version .. "/COPYING")
	zdoc("libarchive-" .. version .. "/NEWS")
	zdoc("libarchive-" .. version .. "/README.md")
end

function test()
	cmd([[
		/usr/bin/bsdtar --version || bsdtar --version
	]])
end
