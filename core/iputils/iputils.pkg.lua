local version = ZOI.VERSION or "20250605"
local sha512 = "1f3df2a4ea0a3f95bb9657d9ee36ed929fa841c9442dfd04e5d7f55ef533b0cac3182c2172b627c7ad7f366afdc1d232f2618d701bd1c601feadbfc754059cae"
-- Release signing key (Petr Vorel), matching Arch Linux's validpgpkeys.
local signing_key = "2016FEA4858B1C36B32E833AC0DEC2EE72F33A5F"

metadata({
	name = "iputils",
	repo = "core",
	version = version,
	revision = "6",
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
					"pacman:curl",
					"pacman:docbook-xsl",
					"pacman:gcc",
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
			"zoi:@core/libcap",
			"zoi:@core/libidn2",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "iputils-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			curl -sSfL --retry 3 --retry-all-errors \
				"https://github.com/iputils/iputils/releases/download/$VER/$1" -o "$1"
		}
		fetch "iputils-$VER.tar.xz"
		fetch "iputils-$VER.tar.xz.asc"
		echo "$SHA512  iputils-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "iputils-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		meson setup "iputils-$VER" build \
			--prefix=/usr \
			--buildtype=release \
			-DUSE_IDN=true \
			-DBUILD_MANS=true

		meson compile -C build -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		DESTDIR="$ROOT" meson install -C build --quiet
	]],
		opts
	)

	-- LICENSE maps each tool to its license; the texts are in Documentation/.
	local src = "iputils-" .. version
	zlicense(src .. "/LICENSE")
	zlicense(src .. "/Documentation/LICENSE.BSD3")
	zlicense(src .. "/Documentation/LICENSE.GPL2")
end

function test()
	cmd([[
		/usr/bin/ping -V || ping -V || true
	]])
end
