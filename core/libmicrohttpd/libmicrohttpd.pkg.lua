local version = ZOI.VERSION or "1.0.11"
local sha512 = "5ab9135e20a7f476e0c74c0b616456e6da9b5e2f8cb44ad4680db90bdb653db50b09f73d4787d7baf418dc5341db0f1068c8122d4f80193b0d9bce327cd3b5ec"
-- Release signing key (Christian Grothoff), matching Arch Linux's
-- validpgpkeys. The sha256 of the same file matches Arch's.
local signing_key = "D8423BCB326C7907033929C7939E6BE1E29FC3CC"

metadata({
	name = "libmicrohttpd",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Small C library to run an HTTP server as part of another application",
	website = "https://www.gnu.org/software/libmicrohttpd/",
	license = "LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Christian Grothoff, Evgeny Grin and others",
		website = "https://www.gnu.org/software/libmicrohttpd/",
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
					"pacman:curl",
					"pacman:gcc",
					"pacman:gnutls",
					"pacman:make",
					"pacman:patch",
					"pacman:pkgconf",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/gnutls",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libmicrohttpd-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/libmicrohttpd" \
				"https://mirrors.kernel.org/gnu/libmicrohttpd" \
				"https://ftp.gnu.org/gnu/libmicrohttpd"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libmicrohttpd-$VER.tar.gz"
		fetch "libmicrohttpd-$VER.tar.gz.sig"
		echo "$SHA512  libmicrohttpd-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	-- 0001: the release header still reports 1.0.10 (Arch fixes it with sed).
	cmd(
		[[
		tar -xf "libmicrohttpd-$VER.tar.gz"
		cd "libmicrohttpd-$VER"
		patch -Np1 -i "$PKGLUADIR/patches/0001-Set-MHD_VERSION-to-1.0.11.patch"
	]],
		opts
	)
end

function build()
	-- Options as Arch (--enable-curl only affects the test suite). HTTPS
	-- support uses GnuTLS.
	cmd(
		[[
		cd "libmicrohttpd-$VER"
		./configure \
			--prefix=/usr \
			--disable-dependency-tracking \
			--disable-static \
			--disable-examples \
			--enable-curl \
			--enable-https=yes \
			--enable-largefile \
			--enable-messages \
			--with-pic
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "libmicrohttpd-$VER" DESTDIR="$ROOT" install]], opts)
	zlicense("libmicrohttpd-" .. version .. "/COPYING")
	zdoc("libmicrohttpd-" .. version .. "/NEWS")
	zdoc("libmicrohttpd-" .. version .. "/README")
end
