local version = ZOI.VERSION or "2.0.1"
local sha512 = "0ffdf15b4380fc89bf11f4f64b74ed999099c0ab3ee39cafd52f933a5000f9b1ed3987c8c13533a7cd92474aadd4cc9909a2e1eabc9143f0cb11746385e5fc57"
-- Upstream does not sign releases; the hash below matches the one Gentoo
-- records for the same release asset (net-libs/libnsl Manifest).

metadata({
	name = "libnsl",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Public client interface library for NIS(YP)",
	website = "https://github.com/thkukuk/libnsl",
	license = "LGPL-2.1-only",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Thorsten Kukuk",
		website = "https://github.com/thkukuk/libnsl",
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
					"pacman:libtirpc",
					"pacman:make",
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
			"zoi:@core/libtirpc",
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
			"https://github.com/thkukuk/libnsl/releases/download/v$VER/libnsl-$VER.tar.xz" \
			-o "libnsl-$VER.tar.xz"
		echo "$SHA512  libnsl-$VER.tar.xz" | sha512sum -c -
		tar -xf "libnsl-$VER.tar.xz"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "libnsl-$VER"
		./configure --prefix=/usr --disable-static
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "libnsl-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)
	local src = "libnsl-" .. version
	zlicense(src .. "/COPYING")
	zdoc(src .. "/AUTHORS")
	zdoc(src .. "/NEWS")
	zdoc(src .. "/README")
end
