local version = ZOI.VERSION or "3.12"
local sha512 = "c54b4db5a8b9afe098c088decd94977746305284d716666a60bac82b4edc0fae4acf828970b5b6fc7d58ecd549f638e17e6958f33a71fedcc7d7415b9228b161"
-- Release signing key (Jim Meyering), listed in the GNU keyring.
local signing_key = "155D3FC500C834486D1EEA677FD9FCCB000BEEEE"

metadata({
	name = "grep",
	repo = "core",
	version = version,
	revision = "6",
	debug = { sub_package = true },
	description = "A string search utility",
	website = "https://www.gnu.org/software/grep/",
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
	bins = { "grep", "egrep", "fgrep" },
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
					"pacman:pcre2",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/pcre2",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "grep-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/grep" \
				"https://mirrors.kernel.org/gnu/grep" \
				"https://ftp.gnu.org/gnu/grep"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "grep-$VER.tar.xz"
		fetch "grep-$VER.tar.xz.sig"
		echo "$SHA512  grep-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "grep-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "grep-$VER"
		./configure \
			--prefix=/usr \
			--disable-gcc-warnings
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "grep-$VER" DESTDIR="$ROOT" install]], opts)

	zlicense("grep-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/grep --version || grep --version
	]])
end
