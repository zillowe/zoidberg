local version = ZOI.VERSION or "0.413"
local sha512 = "d5a2630d929c5e2c015d3d996092d97da351c764f823c1af4c95bc01a7f20e64ccb87c0f37db2220a671397010cd6f83526282669e7f7f1a706fb021a2eca5da"
-- Upstream publishes no release tarball and signs only its git tags, so the
-- source is GitHub's tag archive. The hash matches Gentoo's Manifest.

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
					"pacman:make",
				},
			},
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors \
			"https://github.com/vcrhonek/hwdata/archive/refs/tags/v$VER.tar.gz" \
			-o "hwdata-$VER.tar.gz"
		echo "$SHA512  hwdata-$VER.tar.gz" | sha512sum -c -
		tar -xf "hwdata-$VER.tar.gz"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "hwdata-$VER"

		./configure --prefix=/usr --disable-blacklist
	]],
		opts
	)
end

function package()
	cmd(
		[[
		mkdir -p "$ROOT"

		make -C "hwdata-$VER" DESTDIR="$ROOT" install
	]],
		opts
	)

	-- LICENSE states the dual licensing (GPL-2.0-or-later or XFree86-1.0);
	-- COPYING is the GPL-2.0 text.
	zlicense("hwdata-" .. version .. "/LICENSE")
	zlicense("hwdata-" .. version .. "/COPYING")
end

function test()
	cmd([[
		test -f /usr/share/hwdata/pci.ids || true
	]])
end
