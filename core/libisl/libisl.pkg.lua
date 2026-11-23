local version = ZOI.VERSION or "0.28"
-- isl releases are not signed. This hash matches Gentoo's Manifest, and the
-- file's BLAKE2b matches Arch Linux's b2sums for the same release.
local sha512 = "fa43fe01d62b5a0c4962ec07b06b51143c5781b615de58d76e00e829a8cb35201130db5b1d467773be49e9ecf8f87a8641646c32a852ac6ce53f5add76e4d11a"

metadata({
	name = "libisl",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "Library for manipulating sets and relations of integer points bounded by linear constraints",
	website = "https://libisl.sourceforge.io",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Sven Verdoolaege",
		website = "https://libisl.sourceforge.io",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	provides = { "isl" },
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					-- Arch packaging assumes the base-devel group
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
					"pacman:gmp",
					"pacman:make",
					"pacman:tar",
					"pacman:xz",
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
	cmd(
		[[
		# libisl.sourceforge.io rejects some CI networks; fall back to the
		# SourceForge download mirrors
		fetch() {
			for base in \
				"https://libisl.sourceforge.io" \
				"https://downloads.sourceforge.net/project/libisl"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "isl-$VER.tar.xz"
		echo "$SHA512  isl-$VER.tar.xz" | sha512sum -c -
		tar -xf "isl-$VER.tar.xz"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "isl-$VER"
		./configure --prefix=/usr
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "isl-$VER" DESTDIR="$ROOT" install

		install -dm755 "$ROOT/usr/share/gdb/auto-load/usr/lib/"
		mv "$ROOT"/usr/lib/libisl.so.*-gdb.py "$ROOT/usr/share/gdb/auto-load/usr/lib/"
	]],
		opts
	)

	zlicense("isl-" .. version .. "/LICENSE")
end

function test()
	cmd([[
		test -e /usr/lib/libisl.so || true
	]])
end
