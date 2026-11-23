local version = ZOI.VERSION or "4.4.1"
local sha512 = "591e9fab2f807bfda908f3376fdbf304c3377a6b15d13f3029456722972e361d205b692855de8ddbce64ff3f404873cbfb65f4097ca4a3b81029dc83bafcc67c"
-- Release signing key (Paul D. Smith), listed in the GNU keyring.
local signing_key = "6D4EEB02AD834703510B117680CB727A20C79BB2"

metadata({
	name = "make",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "GNU make utility to maintain groups of programs",
	website = "https://www.gnu.org/software/make",
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
	bins = { "make" },
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
					"pacman:lzip",
					"pacman:make",
					"pacman:tar",
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
	local tarball = "make-" .. version .. ".tar.lz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/make" \
				"https://mirrors.kernel.org/gnu/make" \
				"https://ftp.gnu.org/gnu/make"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "make-$VER.tar.lz"
		fetch "make-$VER.tar.lz.sig"
		echo "$SHA512  make-$VER.tar.lz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "make-$VER.tar.lz"]], opts)
end

function build()
	-- Parlex ships no guile, so GNU make is built without its guile
	-- extension language instead of linking the build host's libguile.
	cmd(
		[[
		cd "make-$VER"
		./configure \
			--prefix=/usr \
			--without-guile
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "make-$VER" DESTDIR="$ROOT" install]], opts)

	zlicense("make-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/make --version || make --version
	]])
end
