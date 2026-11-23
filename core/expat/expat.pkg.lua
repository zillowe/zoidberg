local version = ZOI.VERSION or "2.10.0"
local tag = "R_" .. string.gsub(version, "%.", "_")
local sha512 = "bd61f361d823f67586dad246fa4d4abbe3d22f5a0f9a28401e7a2fc96753d5bae33fbe4068fae72f016998d0da9d8c92edc4abd2fe8a8e4aafc775a8ab547c44"
-- Release signing key (Sebastian Pipping), matching Arch Linux's validpgpkeys.
local signing_key = "3176EF7DB2367F1FCA4F306B1F9B0E909AF37285"

metadata({
	name = "expat",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "An XML parser library",
	website = "https://libexpat.github.io/",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Expat developers",
		website = "https://libexpat.github.io/",
	},
	bins = { "xmlwf" },
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
					"pacman:cmake",
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
local opts = { check = true, env = { VER = version, TAG = tag, SHA512 = sha512 } }

function prepare()
	local tarball = "expat-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			curl -sSfL --retry 3 --retry-all-errors \
				"https://github.com/libexpat/libexpat/releases/download/$TAG/$1" -o "$1"
		}
		fetch "expat-$VER.tar.xz"
		fetch "expat-$VER.tar.xz.asc"
		echo "$SHA512  expat-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "expat-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cmake \
			-B build \
			-D CMAKE_BUILD_TYPE=None \
			-D CMAKE_INSTALL_PREFIX=/usr \
			-S "expat-$VER" \
			-W no-dev
		cmake --build build --verbose -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		mkdir -p "$ROOT"
		DESTDIR="$ROOT" cmake --install build
	]],
		opts
	)

	local src = "expat-" .. version
	zlicense(src .. "/COPYING")
	zdoc(src .. "/AUTHORS")
	zdoc(src .. "/Changes")
	zdoc(src .. "/README.md")
end

function test()
	cmd([[
		/usr/bin/xmlwf -v || xmlwf -v
	]])
end
