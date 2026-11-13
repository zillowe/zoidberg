local version = ZOI.VERSION or "20250605"
local tag = version
local git_url = "https://github.com/iputils/iputils.git"

metadata({
	name = "iputils",
	repo = "core",
	version = version,
	revision = "3",
	debug = { sub_package = true },
	description = "Network monitoring tools, including ping, arping, and tracepath",
	website = "https://github.com/iputils/iputils",
	license = "BSD-3-Clause AND GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Petr Vorel and others",
		website = "https://github.com/iputils/iputils",
	},
	bins = {
		"arping",
		"clockdiff",
		"ping",
		"tracepath",
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
					"pacman:docbook-xsl",
					"pacman:gcc",
					"pacman:git",
					"pacman:libcap",
					"pacman:libidn2",
					"pacman:meson",
					"pacman:ninja",
					"pacman:systemd",
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
		if [ ! -d iputils ]; then
			git clone --depth 1 --branch "%s" "%s" iputils
		fi
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e

		meson setup iputils build \
			--prefix=/usr \
			--buildtype=release \
			-DUSE_IDN=true \
			-DBUILD_MANS=true

		meson compile -C build -j"$(nproc)"
	]])
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		DESTDIR="$ROOT" meson install -C build --quiet
	]],
		root
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/ping -V || ping -V || true
	]])
end
