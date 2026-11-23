local version = ZOI.VERSION or "2.25"
local sha512 = "0c3dfa54858bd0ff6f9567f8224e0ea2b165ab585724adcce63df042703427c813c71fc0affe45950e45c0aa280f038eb9d1a7218df8372b214f99885ba5f2aa"
-- Release signing key (Carlo Wood), listed in the GNU keyring.
local signing_key = "8020B2666305EE2FD53E6827C155A4EEE4E527A2"

metadata({
	name = "which",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "A utility to show the full path of commands",
	website = "https://savannah.gnu.org/projects/which/",
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
	bins = { "which" },
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
					"pacman:gcc",
					"pacman:make",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/glibc",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "which-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/which" \
				"https://mirrors.kernel.org/gnu/which" \
				"https://ftp.gnu.org/gnu/which"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "which-$VER.tar.gz"
		fetch "which-$VER.tar.gz.sig"
		echo "$SHA512  which-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "which-$VER.tar.gz"]], opts)
end

function build()
	cmd(
		[[
		cd "which-$VER"
		./configure --prefix=/usr
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "which-$VER" DESTDIR="$ROOT" install]], opts)

	zlicense("which-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/which sh || which sh
	]])
end
