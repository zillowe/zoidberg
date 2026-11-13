local version = ZOI.VERSION or "18"
local tag = version
local git_url = "https://github.com/rhboot/efibootmgr.git"

metadata({
	name = "efibootmgr",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Linux user-space application to modify the EFI Boot Manager",
	website = "https://github.com/rhboot/efibootmgr",
	license = "GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Peter Jones and others",
		website = "https://github.com/rhboot/efibootmgr",
	},
	bins = {
		"efibootdump",
		"efibootmgr",
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
					"pacman:efivar",
					"pacman:gcc",
					"pacman:git",
					"pacman:make",
					"pacman:pkgconf",
					"pacman:popt",
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

function prepare()
	cmd(string.format(
		[[
		if [ ! -d efibootmgr ]; then
			git clone --depth 1 --branch "%s" "%s" efibootmgr
		fi
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e
		make libdir=/usr/lib sbindir=/usr/bin EFIDIR=parlex -C efibootmgr -j"$(nproc)"
	]])
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		make DESTDIR="$ROOT" libdir=/usr/lib sbindir=/usr/bin EFIDIR=parlex install -C efibootmgr
	]],
		root
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/efibootmgr --help || efibootmgr --help || true
	]])
end
