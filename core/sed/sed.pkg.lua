local version = ZOI.VERSION or "4.10"
local sha512 = "20224df834b363ca1357024234bb93df3929c252c40c7ef3d23e78fc05177c7986e3145a5049d63db746a4dc2c97befb0324a87ea081507292ff6cd5383ee9db"
-- Release signing key (Jim Meyering), listed in the GNU keyring.
local signing_key = "155D3FC500C834486D1EEA677FD9FCCB000BEEEE"

metadata({
	name = "sed",
	repo = "core",
	version = version,
	revision = "6",
	debug = { sub_package = true },
	description = "GNU stream editor",
	website = "https://www.gnu.org/software/sed/",
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
	bins = { "sed" },
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
					"pacman:acl",
					"pacman:attr",
					"pacman:curl",
					"pacman:diffutils",
					"pacman:gcc",
					"pacman:make",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/acl",
			"zoi:@core/attr",
			"zoi:@core/glibc",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "sed-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/sed" \
				"https://mirrors.kernel.org/gnu/sed" \
				"https://ftp.gnu.org/gnu/sed"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "sed-$VER.tar.xz"
		fetch "sed-$VER.tar.xz.sig"
		echo "$SHA512  sed-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "sed-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "sed-$VER"
		./configure \
			--prefix=/usr
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "sed-$VER" DESTDIR="$ROOT" install]], opts)

	zlicense("sed-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/sed --version || sed --version
	]])
end
