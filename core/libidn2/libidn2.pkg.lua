local version = ZOI.VERSION or "2.3.8"
local sha512 = "4d8427c0f115268132f7544e80a808c883ab1406338f6c529b1a586b016d57aedb0857f66166eb8d9f37d70efc9dccf907b673b43b17bcf258c8797db1e829ce"
-- Release signing key (Simon Josefsson), from upstream's published keys.
local signing_key = "B1D2BD1375BECB784CF4F8C4D73CF638C53C06BE"

metadata({
	name = "libidn2",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Free software implementation of IDNA2008, Punycode and TR46",
	website = "https://www.gnu.org/software/libidn/#libidn2",
	license = "(GPL-2.0-or-later OR LGPL-3.0-or-later) AND GPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Simon Josefsson",
		website = "https://josefsson.org",
	},
	bins = { "idn2" },
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
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
					"pacman:libunistring",
					"pacman:make",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/libunistring",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libidn2-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/libidn" \
				"https://mirrors.kernel.org/gnu/libidn" \
				"https://ftp.gnu.org/gnu/libidn"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libidn2-$VER.tar.gz"
		fetch "libidn2-$VER.tar.gz.sig"
		echo "$SHA512  libidn2-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "libidn2-$VER.tar.gz"]], opts)
end

function build()
	cmd(
		[[
		cd "libidn2-$VER"
		./configure --prefix=/usr --disable-static --disable-doc
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "libidn2-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)

	local src = "libidn2-" .. version
	-- COPYING.unicode covers the Unicode data the IDNA tables derive from.
	zlicense(src .. "/COPYING")
	zlicense(src .. "/COPYINGv2")
	zlicense(src .. "/COPYING.LESSERv3")
	zlicense(src .. "/COPYING.unicode")
end
