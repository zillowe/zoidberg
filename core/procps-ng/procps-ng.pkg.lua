local version = ZOI.VERSION or "4.0.7"
local tag = "v" .. version
local git_url = "https://gitlab.com/procps-ng/procps.git"

metadata({
	name = "procps-ng",
	repo = "core",
	version = version,
	revision = "1",
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
					"pacman:autoconf",
					"pacman:automake",
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:git",
					"pacman:libtool",
					"pacman:make",
					"pacman:ncurses",
					"pacman:po4a",
					"pacman:systemd",
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

function prepare()
	cmd(string.format(
		[[
		if [ ! -d procps ]; then
			git clone --depth 1 --branch "%s" "%s" procps
		fi

		cd procps
		./autogen.sh
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e
		cd procps

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
	]])
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		mkdir -p "$ROOT"

		make -C procps DESTDIR="$ROOT" install
	]],
		root
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/ps --version || /usr/bin/free --version || true
	]])
end
