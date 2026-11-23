local version = ZOI.VERSION or "4.0.1"
local sha512 = "431fa8ab90d6b8cdecc38b1618fd89d040185dec3c1150203e20f40f10a16160058f6b8abddd000f6ecb74f4dc42d9fef8111444f1496ab34c34f6b814ed32b7"
-- Upstream does not sign releases. The hash matches Gentoo's Manifest and
-- Arch Linux's sha512sums, and the file matches the sha256 published on
-- https://www.bytereef.org/mpdecimal/download.html.

metadata({
	name = "mpdecimal",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Package for correctly-rounded arbitrary precision decimal floating point arithmetic",
	website = "https://www.bytereef.org/mpdecimal/index.html",
	license = "BSD-2-Clause",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Stefan Krah",
		website = "https://www.bytereef.org/mpdecimal/index.html",
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
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/gcc:libgcc",
			"zoi:@core/gcc:libstdc++",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.bytereef.org/software/mpdecimal/releases"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "mpdecimal-$VER.tar.gz"
		echo "$SHA512  mpdecimal-$VER.tar.gz" | sha512sum -c -
		tar -xf "mpdecimal-$VER.tar.gz"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "mpdecimal-$VER"
		./configure --prefix=/usr
		LDXXFLAGS="${LDFLAGS:-}" make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "mpdecimal-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)
	zlicense("mpdecimal-" .. version .. "/COPYRIGHT.txt")
end
