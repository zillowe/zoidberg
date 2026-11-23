local version = ZOI.VERSION or "1.11.1"
local sha512 = "1b9ecf6b5d0b53be6a7e28f85c63daeecfbf55dee2759dab5eb4647675975ccfe426152e382c30b8a8adb4038d40b312cceac4c56f348fb0977919869aa24669"
-- Upstream publishes the release tarball with a SHA-256 checksum but no
-- signature; the hash below was checked against it.

metadata({
	name = "lz4",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Extremely fast compression algorithm",
	website = "https://lz4.org",
	license = "BSD-2-Clause AND GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Yann Collet",
		website = "https://github.com/lz4/lz4",
	},
	bins = { "lz4", "lz4c", "lz4cat", "unlz4" },
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
					"pacman:meson",
					"pacman:ninja",
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
	local tarball = "lz4-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/lz4/lz4/releases/download/v$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "lz4-$VER.tar.gz"
		echo "$SHA512  lz4-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	cmd([[tar -xf "lz4-$VER.tar.gz"]], opts)
end

function build()
	cmd(
		[[
		cd "lz4-$VER"
		meson setup _build build/meson \
			--prefix=/usr \
			--buildtype=plain \
			-Ddefault_library=shared \
			-Dprograms=true
		meson compile -C _build
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "lz4-$VER"
		meson install -C _build --destdir "$ROOT"
	]],
		opts
	)

	-- lib/ (BSD-2-Clause) and programs/ (GPL-2.0) carry their own licenses;
	-- suffix the directory so they don't collide.
	local src = "lz4-" .. version
	zlicense(src .. "/LICENSE")
	zlicense(src .. "/lib/LICENSE", "LICENSE.lib")
	zlicense(src .. "/programs/COPYING", "COPYING.programs")
end
