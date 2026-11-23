local version = ZOI.VERSION or "1.11.1"
local sha512 = "8322b54a522b0cbbb07916d29ec045c08f8ed94bd8abb5e524038640e90a317667a25be46d95b62b101ed726ade0a51a90fb246cf34c045c38f927f4e439e431"
-- Release signing key (Daniel Stenberg), matches Arch's validpgpkeys.
local signing_key = "27EDEAF22F3ABCEB50DB9A125CC908FDB71E12C2"

metadata({
	name = "libssh2",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "A library implementing the SSH2 protocol as defined by Internet Drafts",
	website = "https://libssh2.org",
	license = "BSD-3-Clause",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The libssh2 project",
		website = "https://libssh2.org",
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
					"pacman:patch",
					"pacman:tar",
					"pacman:xz",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/openssl",
			"zoi:@core/zlib",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libssh2-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://libssh2.org/download" \
				"https://github.com/libssh2/libssh2/releases/download/libssh2-$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libssh2-$VER.tar.xz"
		fetch "libssh2-$VER.tar.xz.asc"
		echo "$SHA512  libssh2-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	-- Security fixes carried by Arch Linux on top of 1.11.1 (the latest
	-- release), applied in Arch's order. They only touch C sources, so the
	-- shipped configure is used as is.
	cmd(
		[[
		tar -xf "libssh2-$VER.tar.xz"
		cd "libssh2-$VER"
		for p in "$PKGLUADIR"/patches/[0-9][0-9][0-9][0-9]-*.patch; do
			patch -Np1 -i "$p"
		done
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "libssh2-$VER"
		./configure \
			--prefix=/usr \
			--disable-static \
			--disable-docker-tests \
			--with-crypto=openssl \
			--with-libz
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "libssh2-$VER" DESTDIR="$ROOT" install]], opts)
	zlicense("libssh2-" .. version .. "/COPYING")
end
