local version = ZOI.VERSION or "1.4.1"

metadata({
	name = "libmpc",
	repo = "core",
	version = version,
	revision = "1",
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
		if [ ! -d "mpc-$VER" ]; then
			curl -sSfL "https://ftp.gnu.org/gnu/mpc/mpc-$VER.tar.xz" -o "mpc-$VER.tar.xz"
			echo "91204cd32f164bd3b7c992d4a6a8ce6519511aadab30f78b6982d0bf8d73e931  mpc-$VER.tar.xz" | sha256sum -c -
			tar -xf "mpc-$VER.tar.xz"
		fi
	]])
end

function build()
	sh([[
		cd "mpc-$VER"
		./configure --prefix=/usr
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C "mpc-$VER" DESTDIR="$ROOT" install
		mv "$ROOT/usr/share/info/mpc.info" "$ROOT/usr/share/info/libmpc.info"
	]])
end

function test()
	cmd([[
		test -e /usr/lib/libmpc.so || true
	]])
end
