local version = ZOI.VERSION or "1.19"

metadata({
	name = "automake",
	repo = "core",
	version = version,
	revision = "2",
	description = "A GNU tool for automatically creating Makefiles",
	website = "https://www.gnu.org/software/automake",
	license = "GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Free Software Foundation",
		website = "https://www.fsf.org",
	},
	bins = {
		"aclocal",
		"aclocal-" .. version,
		"automake",
		"automake-" .. version,
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
					"pacman:gcc",
					"pacman:git",
					"pacman:make",
					"pacman:patch",
					"pacman:perl",
					"pacman:texinfo",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/perl",
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
		if [ ! -d automake ]; then
			git clone --branch "v$VER" https://git.savannah.gnu.org/git/automake.git automake
			cd automake

			# Make amhello-1.0.tar.gz reproducible (together with GZIP_ENV below)
			patch -Np1 -i "$PKGLUADIR/enable-reproducible-builds.patch"

			./bootstrap
		fi
	]])
end

function build()
	sh([[
		cd automake
		./configure --prefix=/usr
		make -j"$(nproc)" GZIP_ENV='-9 -n'
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C automake DESTDIR="$ROOT" install
	]])
end

function test()
	cmd([[
		/usr/bin/automake --version || automake --version
	]])
end
