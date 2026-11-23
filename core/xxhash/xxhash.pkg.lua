local version = ZOI.VERSION or "0.8.4"
local sha512 = "1585ae3f3feded2492e43f4dd5dd43183329c57ffe92afa907f71eb26deaf34beab4434458a2d87e8795a4226339c5b0b493bd8a9186bb6f0c752fa1fdef10e3"
-- Upstream publishes no release tarball and does not sign releases, so this
-- is GitHub's archive of the v<version> tag. The hash matches the one Gentoo
-- records for the same archive (dev-libs/xxhash Manifest).

metadata({
	name = "xxhash",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "Extremely fast non-cryptographic hash algorithm",
	website = "https://cyan4973.github.io/xxHash/",
	license = "BSD-2-Clause AND GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Yann Collet",
		website = "https://github.com/Cyan4973/xxHash",
	},
	bins = { "xxhsum", "xxh32sum", "xxh64sum", "xxh128sum", "xxh3sum" },
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
					"pacman:make",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
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
			"https://github.com/Cyan4973/xxHash/archive/refs/tags/v$VER.tar.gz" \
			-o "xxhash-$VER.tar.gz"
		echo "$SHA512  xxhash-$VER.tar.gz" | sha512sum -c -
		tar -xf "xxhash-$VER.tar.gz"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		make -j"$(nproc)" PREFIX=/usr DISPATCH=1 -C "xxHash-$VER"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		mkdir -p "$ROOT"
		make PREFIX=/usr DISPATCH=1 DESTDIR="$ROOT" -C "xxHash-$VER" install
	]],
		opts
	)

	-- The library is BSD-2-Clause; the xxhsum command line tool is GPL-2.0-or-later.
	zlicense("xxHash-" .. version .. "/LICENSE")
	zlicense("xxHash-" .. version .. "/cli/COPYING", "COPYING.cli")
end

function test()
	cmd([[
		/usr/bin/xxhsum --version || xxhsum --version
	]])
end
