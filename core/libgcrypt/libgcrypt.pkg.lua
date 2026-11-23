local version = ZOI.VERSION or "1.12.4"
local sha512 = "632bac4146ba6b3d5e4672e28b1a8b276fcc8bf17961021240b080c6ea4470e46016968a39ee943d3dcd496bda5c9617bf7704bdec75be55847b738809053d8d"
-- Release signing key (Werner Koch, dist signing 2020), matches Arch Linux's
-- validpgpkeys. Releases are signed by both Werner Koch and Niibe Yutaka;
-- one valid signature from this key is required.
local signing_key = "6DAA6E64A76D2840571B4902528897B826403ADA"

metadata({
	name = "libgcrypt",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "General purpose cryptographic library based on the code from GnuPG",
	website = "https://www.gnupg.org/related_software/libgcrypt/",
	license = "BSD-3-Clause AND (BSD-3-Clause OR GPL-2.0-only) AND GPL-2.0-or-later AND LGPL-2.0-or-later AND LGPL-2.1-or-later AND X11 AND LicenseRef-scancode-public-domain AND LicenseRef-OCB1",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The GnuPG Project",
		website = "https://www.gnupg.org",
	},
	bins = {
		"dumpsexp",
		"hmac256",
		"mpicalc",
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
					"pacman:bzip2",
					"pacman:curl",
					"pacman:gcc",
					"pacman:libgpg-error",
					"pacman:make",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/libgpg-error",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "libgcrypt-" .. version .. ".tar.bz2"
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.gnupg.org/ftp/gcrypt/libgcrypt" \
				"https://gnupg.org/ftp/gcrypt/libgcrypt"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libgcrypt-$VER.tar.bz2"
		fetch "libgcrypt-$VER.tar.bz2.sig"
		echo "$SHA512  libgcrypt-$VER.tar.bz2" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "libgcrypt-$VER.tar.bz2"]], opts)
end

function build()
	cmd(
		[[
		cd "libgcrypt-$VER"
		./configure \
			--prefix=/usr \
			--disable-static \
			--disable-padlock-support
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "libgcrypt-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)

	zlicense("libgcrypt-" .. version .. "/COPYING")
	zlicense("libgcrypt-" .. version .. "/COPYING.LIB")
	zlicense("libgcrypt-" .. version .. "/LICENSES")
end
