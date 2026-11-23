local version = ZOI.VERSION or "20241231"
local sha512 = "0c5858f6068226afd9b3744020a3826a1236b62f90b6eff30ad17657a194017eaab9f8e090eb744902f47b997f63277b20509a27d1945c42ad9597bb734cad73"
-- Release signing key (Bruno Haible, Open Source Development), listed in
-- Arch Linux's validpgpkeys. The key expired in 2025-02, after this release
-- was signed; the signature was made while it was valid and still verifies.
local signing_key = "9001B85AF9E1B83DF1BDA942F5BE8B267C6A406D"

metadata({
	name = "gnulib-l10n",
	repo = "core",
	version = version,
	revision = "1",
	description = "The Gnulib localizations",
	website = "https://www.gnu.org/software/gnulib/",
	license = "LGPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Gnulib developers",
		website = "https://www.gnu.org/software/gnulib/",
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
					"pacman:gettext",
					"pacman:make",
					"pacman:tar",
				},
			},
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "gnulib-l10n-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/gnulib" \
				"https://ftp.gnu.org/gnu/gnulib" \
				"https://mirrors.kernel.org/gnu/gnulib"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "gnulib-l10n-$VER.tar.gz"
		fetch "gnulib-l10n-$VER.tar.gz.sig"
		echo "$SHA512  gnulib-l10n-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "gnulib-l10n-$VER.tar.gz"]], opts)
end

function build()
	cmd(
		[[
		cd "gnulib-l10n-$VER"
		./configure --prefix=/usr
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		cd "gnulib-l10n-$VER"
		make DESTDIR="$ROOT" install
	]],
		opts
	)
	zlicense("gnulib-l10n-" .. version .. "/COPYING")
end
