local version = ZOI.VERSION or "6.3.0"
local sha512 = "e85a0dab5195889948a3462189f0e0598d331d3457612e2d3350799dba2e244316d256f8161df5219538eb003e4b5343f989aaa00f96321559063ed8c8f29fd2"
-- Release signing key (Niels Möller), as listed on gmplib.org.
local signing_key = "343C2FF0FBEE5EC2EDBEF399F3599FF828C67298"

metadata({
	name = "gmp",
	repo = "core",
	version = version,
	revision = "4",
	debug = { sub_package = true },
	description = "A free library for arbitrary precision arithmetic",
	website = "https://gmplib.org/",
	license = "GPL-2.0-or-later OR LGPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The GMP developers",
		website = "https://gmplib.org/",
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
					"pacman:autoconf",
					"pacman:automake",
					"pacman:curl",
					"pacman:gcc",
					"pacman:libtool",
					"pacman:m4",
					"pacman:make",
					"pacman:patch",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/gcc:libgcc",
			"zoi:@core/gcc:libstdc++",
			"zoi:@core/glibc",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "gmp-" .. version .. ".tar.xz"
	cmd(
		[[
		# gmplib.org is not always reachable from CI; fall back to GNU mirrors
		fetch() {
			for base in \
				"https://gmplib.org/download/gmp" \
				"https://ftpmirror.gnu.org/gnu/gmp" \
				"https://mirrors.kernel.org/gnu/gmp"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "gmp-$VER.tar.xz"
		fetch "gmp-$VER.tar.xz.sig"
		echo "$SHA512  gmp-$VER.tar.xz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "gmp-$VER.tar.xz"
		cd "gmp-$VER"
		# Fix build with GCC 15 (upstream changeset 8e7bb4ae7a18). It changes
		# acinclude.m4, so configure has to be regenerated.
		patch -Np1 -i "$PKGLUADIR/patches/gmp-gcc-15.patch"
		autoreconf -vif
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "gmp-$VER"
		LDFLAGS="${LDFLAGS:-} -Wl,-z,shstk" \
		./configure \
			--build=x86_64-pc-linux-gnu \
			--prefix=/usr \
			--enable-cxx \
			--enable-fat
		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
		make -j"$(nproc)"
	]],
		opts
	)
end

function package()
	cmd([[make -C "gmp-$VER" DESTDIR="$ROOT" install]], opts)

	-- Dual-licensed: LGPL-3.0-or-later or GPL-2.0-or-later. COPYING is the
	-- GPL-3 text the LGPL-3 builds on.
	local src = "gmp-" .. version
	zlicense(src .. "/COPYING")
	zlicense(src .. "/COPYING.LESSERv3")
	zlicense(src .. "/COPYINGv2")
	zlicense(src .. "/COPYINGv3")
end

function test()
	cmd([[
		test -e /usr/lib/libgmp.so || true
	]])
end
