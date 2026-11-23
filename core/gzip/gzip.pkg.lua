local version = ZOI.VERSION or "1.15"
local sha512 = "4a2ff92df8a49e1bbcbf65c3a70434660ad02f084d1b453f7dcaa8ee84f248cc4bb06f62bd8e57fea1e05ba1275c7c584ce97a58856e4ca6105f6417c8efbc3c"
-- Release signing key (Jim Meyering), listed in the GNU keyring.
local signing_key = "155D3FC500C834486D1EEA677FD9FCCB000BEEEE"

metadata({
	name = "gzip",
	repo = "core",
	version = version,
	revision = "6",
	debug = { sub_package = true },
	description = "GNU compression utility",
	website = "https://www.gnu.org/software/gzip/",
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
	bins = {
		"gunzip",
		"gzexe",
		"gzip",
		"uncompress",
		"zcat",
		"zcmp",
		"zdiff",
		"zegrep",
		"zfgrep",
		"zforce",
		"zgrep",
		"zless",
		"zmore",
		"znew",
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
			"zoi:@core/glibc",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "gzip-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/gzip" \
				"https://mirrors.kernel.org/gnu/gzip" \
				"https://ftp.gnu.org/gnu/gzip"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "gzip-$VER.tar.xz"
		fetch "gzip-$VER.tar.xz.sig"
		echo "$SHA512  gzip-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "gzip-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "gzip-$VER"
		./configure \
			--prefix=/usr \
			--disable-gcc-warnings
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "gzip-$VER" DESTDIR="$ROOT" install]], opts)

	zlicense("gzip-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/gzip --version || gzip --version
	]])
end
