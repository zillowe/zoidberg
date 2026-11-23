local version = ZOI.VERSION or "1.4.21"
local sha512 = "efe5ec212f6431129a79667f098b2efe2e824122112f73a675deccb9c0d8c9b0bc9e3bf50c9cd5c0b894dc0af1b3f02253e5e67893fb9548a6a9d3bed7c829f7"
-- Release signing key (Eric Blake), listed in the GNU keyring.
local signing_key = "71C2CC22B1C4602927D2F3AAA7A16B4A2527436A"

metadata({
	name = "m4",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "The GNU macro processor",
	website = "https://www.gnu.org/software/m4",
	license = "GPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Free Software Foundation",
		website = "https://www.fsf.org",
	},
	bins = { "m4" },
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
					-- Arch packaging assumes the base-devel group
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
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
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "m4-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/m4" \
				"https://mirrors.kernel.org/gnu/m4" \
				"https://ftp.gnu.org/gnu/m4"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "m4-$VER.tar.xz"
		fetch "m4-$VER.tar.xz.sig"
		echo "$SHA512  m4-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "m4-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "m4-$VER"
		./configure \
			--prefix=/usr \
			--disable-gcc-warnings
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "m4-$VER" DESTDIR="$ROOT" install]], opts)

	zlicense("m4-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/m4 --version || m4 --version
	]])
end
