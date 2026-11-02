local version = ZOI.VERSION or "23.7"
local tag = "v" .. version
local git_url = "https://gitlab.com/psmisc/psmisc.git"

metadata({
	name = "psmisc",
	repo = "core",
	version = version,
	revision = "2",
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
		if [ ! -d psmisc ]; then
			git clone --depth 1 --branch "%s" "%s" psmisc
		fi

		cd psmisc
		./autogen.sh
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e
		cd psmisc

		./configure --prefix=/usr
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

		make -C psmisc DESTDIR="$ROOT" install
	]],
		root
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/pstree -V || /usr/bin/killall -V || true
	]])
end
