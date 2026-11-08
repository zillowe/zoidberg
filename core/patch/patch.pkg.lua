local version = ZOI.VERSION or "2.8.1"

metadata({
	name = "patch",
	repo = "core",
	version = version,
	revision = "1",
	description = "A utility to apply patch files to original sources",
	website = "https://www.gnu.org/software/patch/",
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
	bins = { "patch" },
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
					"pacman:ed",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:git",
					"pacman:make",
					"pacman:python",
					"pacman:texinfo",
					"pacman:wget",
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
		if [ ! -d patch ]; then
			git clone --branch "v$VER" https://git.savannah.gnu.org/git/patch.git patch
			cd patch
			git submodule update --init
			./bootstrap
		fi
	]])
end

function build()
	-- Parlex ships no libattr, so build without extended attribute support
	-- instead of linking whatever libattr the build host provides.
	sh([[
		cd patch
		./configure \
			--prefix=/usr \
			--disable-xattr
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C patch DESTDIR="$ROOT" install
	]])
end

function test()
	cmd([[
		/usr/bin/patch --version || patch --version
	]])
end
