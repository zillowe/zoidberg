local version = ZOI.VERSION or "1.61"
local sha512 = "3e59eb52d061709fd8dfe56a4b36d2d5b49dd5e0c90c283899669d6a355286cb3a3f851631f8456c78c48b652bb31a4c1f8b081ccdf87e5db64b313d141a7670"
-- Release signing key (Werner Koch, dist signing 2020), matches Arch Linux's
-- validpgpkeys. Releases are signed by both Werner Koch and Niibe Yutaka;
-- one valid signature from this key is required.
local signing_key = "6DAA6E64A76D2840571B4902528897B826403ADA"

metadata({
	name = "libgpg-error",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Support library for libgcrypt",
	website = "https://www.gnupg.org/related_software/libgpg-error/",
	license = "LGPL-2.1-or-later AND (BSD-3-Clause OR LGPL-2.1-or-later) AND FSFULLR AND GPL-2.0-or-later",
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
		"gpg-error",
		"gpgrt-config",
		"yat2m",
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
	local tarball = "libgpg-error-" .. version .. ".tar.bz2"
	cmd(
		[[
		fetch() {
			for base in \
				"https://www.gnupg.org/ftp/gcrypt/libgpg-error" \
				"https://gnupg.org/ftp/gcrypt/libgpg-error"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libgpg-error-$VER.tar.bz2"
		fetch "libgpg-error-$VER.tar.bz2.sig"
		echo "$SHA512  libgpg-error-$VER.tar.bz2" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "libgpg-error-$VER.tar.bz2"]], opts)
end

function build()
	cmd(
		[[
		cd "libgpg-error-$VER"
		./configure --prefix=/usr
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "libgpg-error-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)

	zlicense("libgpg-error-" .. version .. "/COPYING")
	zlicense("libgpg-error-" .. version .. "/COPYING.LIB")
end
