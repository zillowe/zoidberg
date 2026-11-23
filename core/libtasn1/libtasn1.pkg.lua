local version = ZOI.VERSION or "4.21.0"
local sha512 = "6a581c4c072b168bf29a0dec7e59a9329a798e392b7d1033791d0e3166a5d1164e2a7065373a84018d500a01563657900c318b1fd437c227c3174b754f9998d3"
-- Release signing key (Simon Josefsson), from upstream's published keys.
local signing_key = "B1D2BD1375BECB784CF4F8C4D73CF638C53C06BE"

metadata({
	name = "libtasn1",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "The ASN.1 library used in GnuTLS",
	website = "https://www.gnu.org/software/libtasn1/",
	license = "GPL-3.0-or-later AND LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Free Software Foundation",
		website = "https://www.fsf.org",
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
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
					"pacman:make",
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
	local tarball = "libtasn1-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/libtasn1" \
				"https://mirrors.kernel.org/gnu/libtasn1" \
				"https://ftp.gnu.org/gnu/libtasn1"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libtasn1-$VER.tar.gz"
		fetch "libtasn1-$VER.tar.gz.sig"
		echo "$SHA512  libtasn1-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "libtasn1-$VER.tar.gz"]], opts)
end

function build()
	cmd(
		[[
		cd "libtasn1-$VER"
		./configure --prefix=/usr --disable-static --disable-doc
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "libtasn1-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)

	local src = "libtasn1-" .. version
	zlicense(src .. "/COPYING")
	zlicense(src .. "/COPYING.LESSERv2")
end
