local version = ZOI.VERSION or "1.4.1"
local sha512 = "cdfbe64e80e30df64dbd536e8104a6bb10471582415d5b45a1dd30eb2a312781b38389a9531243413c14e0f88866a35159b20e77900718f28c1030253a1305b9"
-- Release signing key (Andreas Enge), as listed on multiprecision.org.
local signing_key = "AD17A21EF8AED8F1CC02DBD9F7D5C9BF765C61E3"

metadata({
	name = "libmpc",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "Library for the arithmetic of complex numbers with arbitrarily high precision",
	website = "https://www.multiprecision.org/",
	license = "LGPL-3.0-only",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The MPC developers",
		website = "https://www.multiprecision.org/",
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
					"pacman:gcc",
					"pacman:gmp",
					"pacman:make",
					"pacman:mpfr",
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
			"zoi:@core/mpfr",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "mpc-" .. version .. ".tar.xz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/mpc" \
				"https://mirrors.kernel.org/gnu/mpc" \
				"https://ftp.gnu.org/gnu/mpc"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "mpc-$VER.tar.xz"
		fetch "mpc-$VER.tar.xz.sig"
		echo "$SHA512  mpc-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd([[tar -xf "mpc-$VER.tar.xz"]], opts)
end

function build()
	cmd(
		[[
		cd "mpc-$VER"
		./configure --prefix=/usr
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd(
		[[
		make -C "mpc-$VER" DESTDIR="$ROOT" install
		mv "$ROOT/usr/share/info/mpc.info" "$ROOT/usr/share/info/libmpc.info"
	]],
		opts
	)

	zlicense("mpc-" .. version .. "/COPYING.LESSER")
end

function test()
	cmd([[
		test -e /usr/lib/libmpc.so || true
	]])
end
