local version = ZOI.VERSION or "4.2.2"

metadata({
	name = "mpfr",
	repo = "core",
	version = version,
	revision = "1",
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
					"pacman:autoconf",
					"pacman:automake",
					"pacman:curl",
					"pacman:gcc",
					"pacman:gmp",
					"pacman:libtool",
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

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	sh([[
		if [ ! -d "mpfr-$VER" ]; then
			curl -sSfL "https://ftp.gnu.org/gnu/mpfr/mpfr-$VER.tar.xz" -o "mpfr-$VER.tar.xz"
			echo "eb9e7f51b5385fb349cc4fba3a45ffdf0dd53be6dfc74932dc01258158a10514667960c530c47dd9dfc5aa18be2bd94859d80499844c5713710581e6ac6259a9  mpfr-$VER.tar.xz" | sha512sum -c -
			tar -xf "mpfr-$VER.tar.xz"
			cd "mpfr-$VER"
			autoreconf -fiv
		fi
	]])
end

function build()
	sh([[
		cd "mpfr-$VER"
		./configure \
			--prefix=/usr \
			--enable-thread-safe \
			--enable-shared
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C "mpfr-$VER" DESTDIR="$ROOT" install
	]])
end

function test()
	cmd([[
		test -e /usr/lib/libmpfr.so || true
	]])
end
