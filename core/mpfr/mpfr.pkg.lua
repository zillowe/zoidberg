local version = ZOI.VERSION or "4.2.2"
local sha512 = "eb9e7f51b5385fb349cc4fba3a45ffdf0dd53be6dfc74932dc01258158a10514667960c530c47dd9dfc5aa18be2bd94859d80499844c5713710581e6ac6259a9"
-- Release signing key (Vincent Lefèvre), as listed on mpfr.org.
local signing_key = "A534BE3F83E241D918280AEB5831D11A0D4DB02A"

metadata({
	name = "mpfr",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "Multiple-precision floating-point library",
	website = "https://www.mpfr.org/",
	license = "LGPL-3.0-or-later AND GPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The MPFR developers",
		website = "https://www.mpfr.org/",
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
					-- Arch packaging assumes the base-devel group
					"pacman:base-devel",
					"pacman:curl",
					"pacman:gcc",
					"pacman:gmp",
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
			"zoi:@core/gmp",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "mpfr-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/mpfr" \
				"https://mirrors.kernel.org/gnu/mpfr" \
				"https://ftp.gnu.org/gnu/mpfr"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "mpfr-$VER.tar.xz"
		fetch "mpfr-$VER.tar.xz.sig"
		echo "$SHA512  mpfr-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "mpfr-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "mpfr-$VER"
		./configure \
			--prefix=/usr \
			--enable-thread-safe \
			--enable-shared
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "mpfr-$VER" DESTDIR="$ROOT" install]], opts)

	-- The library is LGPL-3.0-or-later; COPYING (GPL-3.0) is the text it
	-- builds on.
	zlicense("mpfr-" .. version .. "/COPYING.LESSER")
	zlicense("mpfr-" .. version .. "/COPYING")
end

function test()
	cmd([[
		test -e /usr/lib/libmpfr.so || true
	]])
end
