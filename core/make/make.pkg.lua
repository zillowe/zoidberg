local version = ZOI.VERSION or "4.4.1"

metadata({
	name = "make",
	repo = "core",
	version = version,
	revision = "1",
	description = "GNU make utility to maintain groups of programs",
	website = "https://www.gnu.org/software/make",
	license = "GPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Free Software Foundation",
		website = "https://www.fsf.org",
	},
	bins = { "make" },
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
					"pacman:lzip",
					"pacman:make",
					"pacman:tar",
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
		if [ ! -d "make-$VER" ]; then
			curl -sSfL "https://ftp.gnu.org/gnu/make/make-$VER.tar.lz" -o "make-$VER.tar.lz"
			tar -xf "make-$VER.tar.lz"
		fi
	]])
end

function build()
	-- Parlex ships no guile, so GNU make is built without its guile
	-- extension language instead of linking the build host's libguile.
	sh([[
		cd "make-$VER"
		./configure \
			--prefix=/usr \
			--without-guile
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C "make-$VER" DESTDIR="$ROOT" install
	]])
end

function test()
	cmd([[
		/usr/bin/make --version || make --version
	]])
end
