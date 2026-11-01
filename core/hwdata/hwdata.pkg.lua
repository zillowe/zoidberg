local version = ZOI.VERSION or "0.412"
local tag = "v" .. version
local git_url = "https://github.com/vcrhonek/hwdata.git"

metadata({
	name = "hwdata",
	repo = "core",
	version = version,
	revision = "1",
	description = "Hardware identification databases (pci.ids, usb.ids, etc.)",
	website = "https://github.com/vcrhonek/hwdata",
	license = "GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Vitezslav Crhonek",
		website = "https://github.com/vcrhonek/hwdata",
	},
	scope = "system",
	scopes = { "system" },
	platforms = { "linux" },
	types = { "source" },
	zoios = true,
})

dependencies({
	build = {
		types = {
			source = {
				required = {
					"pacman:git",
					"pacman:make",
				},
			},
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d hwdata ]; then
			git clone --depth 1 --branch "%s" "%s" hwdata
		fi
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e
		cd hwdata

		./configure --prefix=/usr --disable-blacklist
	]])
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		mkdir -p "$ROOT"

		make -C hwdata DESTDIR="$ROOT" install
	]],
		root
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		test -f /usr/share/hwdata/pci.ids || true
	]])
end
