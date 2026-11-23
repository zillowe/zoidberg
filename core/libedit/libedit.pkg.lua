-- Upstream versions look like "20260512-3.1"; the recipe uses "_" (as Arch
-- does) and turns it back into "-" for the tarball name.
local version = ZOI.VERSION or "20260512_3.1"
local sha512 = "8d6d04f4d50e7f30bf426b009454400d3ad9a840ddf075cc5eabd9a551f325f923c02d56d7b4535820a613ff01c5f77074b6df9e8e83a1f6bb4124dd87133623"
-- Upstream does not sign releases. The tarball's sha256 and b2sum match Arch
-- Linux's .SRCINFO for libedit 20260512_3.1.

local upstream_version = version:gsub("_", "-")

metadata({
	name = "libedit",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Command line editor library providing generic line editing, history, and tokenization functions",
	website = "https://thrysoee.dk/editline/",
	license = "BSD-3-Clause",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Jess Thrysoee and the NetBSD Project",
		website = "https://thrysoee.dk/editline/",
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
					"pacman:gzip",
					"pacman:make",
					"pacman:ncurses",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/ncurses",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = upstream_version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors \
			"https://thrysoee.dk/editline/libedit-$VER.tar.gz" \
			-o "libedit-$VER.tar.gz"
		echo "$SHA512  libedit-$VER.tar.gz" | sha512sum -c -
		tar -xf "libedit-$VER.tar.gz"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "libedit-$VER"
		./configure --prefix=/usr --disable-static
		make -j"$(nproc)" V=1
	]],
		opts
	)
end

function package()
	cmd([[make -C "libedit-$VER" DESTDIR="$ROOT" install]], opts)
	local src = "libedit-" .. upstream_version
	zlicense(src .. "/COPYING")
	zdoc(src .. "/ChangeLog")
end
