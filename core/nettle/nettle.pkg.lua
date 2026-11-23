local version = ZOI.VERSION or "4.0"
local sha512 = "833303d94f5a67094011ad4dd931fffdb9adf679b4df241a544a08194a66e6e449398b704ba5b29d52c1c3b5ada6f6dc18b24d1adb3382a68470a11645bf13cd"
-- Release signing key (Niels Möller), matches Arch Linux's validpgpkeys.
local signing_key = "343C2FF0FBEE5EC2EDBEF399F3599FF828C67298"

metadata({
	name = "nettle",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "A low-level cryptographic library",
	website = "https://www.lysator.liu.se/~nisse/nettle/",
	license = "LGPL-3.0-or-later OR GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Niels Möller",
		website = "https://www.lysator.liu.se/~nisse/nettle/",
	},
	bins = {
		"nettle-hash",
		"nettle-lfib-stream",
		"nettle-pbkdf2",
		"pkcs1-conv",
		"sexp-conv",
	},
	provides = {
		"libnettle.so",
		"libhogweed.so",
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
					"pacman:gmp",
					"pacman:make",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/gmp",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "nettle-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/nettle" \
				"https://ftp.gnu.org/gnu/nettle" \
				"https://mirrors.kernel.org/gnu/nettle"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "nettle-$VER.tar.gz"
		fetch "nettle-$VER.tar.gz.sig"
		echo "$SHA512  nettle-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "nettle-$VER.tar.gz"]], opts)
end

function build()
	cmd(
		[[
		cd "nettle-$VER"
		./configure --prefix=/usr --disable-static
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "nettle-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)

	zlicense("nettle-" .. version .. "/COPYINGv2")
	zlicense("nettle-" .. version .. "/COPYINGv3")
	zlicense("nettle-" .. version .. "/COPYING.LESSERv3")
end
