local version = ZOI.VERSION or "5.8.4"
local sha512 = "6ade85c1bcff651cdb9543d0b9e7d932c50c9a45e362ada3ef5edf173cd6fb18786f24bc73058db37440f3d92d2178a4e24448f725f4f22146c9a63ed15be432"
-- Release signing key (Lasse Collin), from upstream's published keys.
local signing_key = "3690C240CE51B4670D30AD1C38EE757D69184620"

metadata({
	name = "xz",
	repo = "core",
	version = version,
	revision = "5",
	debug = { sub_package = true },
	description = "Library and command line tools for XZ and LZMA compressed files",
	website = "https://tukaani.org/xz/",
	license = "GPL-2.0-or-later AND 0BSD AND LicenseRef-Public-Domain AND LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Lasse Collin and others",
		website = "https://tukaani.org/xz/",
	},
	bins = {
		"xz",
		"unxz",
		"xzcat",
		"lzma",
		"unlzma",
		"lzcat",
		"xzdec",
		"lzmadec",
		"xzdiff",
		"lzdiff",
		"xzcmp",
		"lzcmp",
		"xzgrep",
		"lzgrep",
		"xzegrep",
		"lzegrep",
		"xzfgrep",
		"lzfgrep",
		"xzless",
		"lzless",
		"xzmore",
		"lzmore",
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
					"pacman:diffutils",
					"pacman:doxygen",
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
	local tarball = "xz-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/tukaani-project/xz/releases/download/v$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "xz-$VER.tar.xz"
		fetch "xz-$VER.tar.xz.sig"
		echo "$SHA512  xz-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "xz-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "xz-$VER"

		./configure \
			--prefix=/usr \
			--disable-rpath \
			--enable-doxygen \
			--disable-werror

		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		mkdir -p "$ROOT"

		make -C "xz-$VER" DESTDIR="$ROOT" install
	]],
		opts
	)

	-- COPYING says which parts are under which license; the rest are the
	-- license texts it refers to.
	for _, f in ipairs({ "COPYING", "COPYING.0BSD", "COPYING.GPLv2", "COPYING.GPLv3", "COPYING.LGPLv2.1" }) do
		zlicense("xz-" .. version .. "/" .. f)
	end
end

function test()
	cmd([[
		/usr/bin/xz --version || xz --version
	]])
end
