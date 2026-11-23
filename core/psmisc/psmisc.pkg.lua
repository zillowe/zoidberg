local version = ZOI.VERSION or "23.7"
local sha512 = "8180d24355b3b0f3102044916d078b1aa9a1af3d84f1e14db79e33e505390167012adbb1a8a5f47a692f3a14aba1eb5f1f8f37f328392e8635b89966af9b2128"
-- Release signing key (Craig Small), as listed by Arch Linux.
local signing_key = "5D2FB320B825D93904D205193938F96BDF50FEA5"

metadata({
	name = "psmisc",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "Miscellaneous procfs tools (fuser, killall, pstree)",
	website = "https://gitlab.com/psmisc/psmisc",
	license = "GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Craig Small and others",
		website = "https://gitlab.com/psmisc/psmisc",
	},
	bins = {
		"fuser",
		"killall",
		"peekfd",
		"prtstat",
		"pslog",
		"pstree",
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
					"pacman:gcc",
					"pacman:gettext",
					"pacman:make",
					"pacman:ncurses",
					"pacman:po4a",
					"pacman:tar",
					"pacman:xz",
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
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "psmisc-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://downloads.sourceforge.net/project/psmisc/psmisc"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "psmisc-$VER.tar.xz"
		fetch "psmisc-$VER.tar.xz.asc"
		echo "$SHA512  psmisc-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "psmisc-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "psmisc-$VER"

		./configure --prefix=/usr
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "psmisc-$VER" DESTDIR="$ROOT" install]], opts)

	zlicense("psmisc-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/pstree -V || /usr/bin/killall -V || true
	]])
end
