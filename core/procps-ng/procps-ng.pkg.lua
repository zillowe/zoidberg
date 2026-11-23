local version = ZOI.VERSION or "4.0.7"
local sha512 = "8c4cd796af9edcf027661b7f97a02f47d8c96c732b334f5943278780026e774ab490ae0a836ee67d2624f0762510f4098fec23e13f405c2263a1ee1a17edf35e"
-- Release signing key (Craig Small), as listed by Arch Linux.
local signing_key = "5D2FB320B825D93904D205193938F96BDF50FEA5"

metadata({
	name = "procps-ng",
	repo = "core",
	version = version,
	revision = "6",
	debug = { sub_package = true },
	description = "Utilities for monitoring your system and its processes (ps, top, free, etc.)",
	website = "https://gitlab.com/procps-ng/procps",
	license = "GPL-2.0-or-later AND LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Craig Small and others",
		website = "https://gitlab.com/procps-ng/procps",
	},
	bins = {
		"free",
		"pgrep",
		"pkill",
		"pmap",
		"ps",
		"pwdx",
		"slabtop",
		"sysctl",
		"tload",
		"top",
		"vmstat",
		"w",
		"watch",
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
					"pacman:pkgconf",
					"pacman:po4a",
					"pacman:systemd",
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
			"zoi:@core/systemd:libs",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "procps-ng-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://downloads.sourceforge.net/project/procps-ng/Production"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "procps-ng-$VER.tar.xz"
		fetch "procps-ng-$VER.tar.xz.asc"
		echo "$SHA512  procps-ng-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "procps-ng-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "procps-ng-$VER"

		./configure \
			--prefix=/usr \
			--sysconfdir=/etc \
			--libdir=/usr/lib \
			--bindir=/usr/bin \
			--sbindir=/usr/bin \
			--enable-watch8bit \
			--with-systemd \
			--disable-modern-top \
			--disable-kill

		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "procps-ng-$VER" DESTDIR="$ROOT" install]], opts)

	zlicense("procps-ng-" .. version .. "/COPYING")
	zlicense("procps-ng-" .. version .. "/COPYING.LIB")
end

function test()
	cmd([[
		/usr/bin/ps --version || /usr/bin/free --version || true
	]])
end
