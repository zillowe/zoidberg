-- NOTE: libtool must be rebuilt (revision bump) with each new GCC version.
local version = ZOI.VERSION or "2.6.2"
local commit = "309bb53a8adfb22c6e5869cc8da049bf123e5438"

metadata({
	name = "libtool",
	repo = "core",
	version = version,
	revision = "1",
	description = "A generic library support script",
	website = "https://www.gnu.org/software/libtool",
	license = "GPL-2.0-or-later WITH Libtool-exception AND LGPL-2.1-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Free Software Foundation",
		website = "https://www.fsf.org",
	},
	bins = { "libtool", "libtoolize" },
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
					"pacman:gcc",
					"pacman:git",
					"pacman:help2man",
					"pacman:m4",
					"pacman:make",
					"pacman:texinfo",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/glibc",
			"zoi:@core/tar",
		},
	},
})

-- Runs a script in a subshell with `set -e` and fails the build on error.
local function sh(script)
	local loc = LOCATION or {}
	local root = loc.ROOT or (STAGING_DIR and (STAGING_DIR .. "/usrroot")) or ""
	local env = "VER='" .. version .. "'\n"
		.. "COMMIT='" .. commit .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	-- Upstream's .gitmodules pulls gnulib and gnulib's bootstrap module.
	sh([[
		if [ ! -d libtool ]; then
			git clone https://git.savannah.gnu.org/git/libtool.git libtool
			cd libtool
			git checkout "$COMMIT"
			git submodule update --init
			./bootstrap
		fi
	]])
end

function build()
	sh([[
		cd libtool
		./configure \
			--prefix=/usr \
			lt_cv_sys_lib_dlsearch_path_spec="/usr/lib /usr/lib32"
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C libtool DESTDIR="$ROOT" install
	]])
end

function test()
	cmd([[
		/usr/bin/libtool --version || libtool --version
	]])
end
