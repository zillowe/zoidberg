local version = ZOI.VERSION or "2.7.5"
local sha512 = "30d03ca78a30eedf98c9923a81fd279ecf91aee08c398a467533e856079c61e70ecbf37755c08c288c1c29dfaf1279845ccfb824eb06443cbf2a4602de441a44"
-- Release signing key (Flex Releases), published with every upstream release
-- and in the release announcement.
local signing_key = "56D664C70CC2364CF5164914B7DFE8BB6C241FED"

metadata({
	name = "flex",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "A tool for generating text-scanning programs",
	website = "https://github.com/westes/flex",
	license = "BSD-3-Clause-flex",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Flex Project",
		website = "https://github.com/westes/flex",
	},
	bins = { "flex", "flex++", "lex" },
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
					"pacman:m4",
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
			"zoi:@core/m4",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "flex-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/westes/flex/releases/download/v$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "flex-$VER.tar.gz"
		fetch "flex-$VER.tar.gz.sig"
		echo "$SHA512  flex-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "flex-$VER.tar.gz"]], opts)
end

function build()
	cmd(
		[[
		cd "flex-$VER"
		./configure --prefix=/usr
		# Prevent excessive overlinking due to libtool
		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "flex-$VER" DESTDIR="$ROOT" install
		ln -sf flex "$ROOT/usr/bin/lex"
	]],
		opts
	)

	zlicense("flex-" .. version .. "/COPYING", "license.txt")
end

function test()
	cmd([[
		/usr/bin/flex --version || flex --version
	]])
end
