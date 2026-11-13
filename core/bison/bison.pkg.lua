local version = ZOI.VERSION or "3.8.2"

metadata({
	name = "bison",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "The GNU general-purpose parser generator",
	website = "https://www.gnu.org/software/bison/bison.html",
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
	bins = { "bison", "yacc" },
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
					"pacman:gettext",
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
			"zoi:@core/bash",
			"zoi:@core/gettext",
			"zoi:@core/glibc",
			"zoi:@core/m4",
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
		if [ ! -d "bison-$VER" ]; then
			curl -sSfL "https://ftp.gnu.org/gnu/bison/bison-$VER.tar.xz" -o "bison-$VER.tar.xz"
			tar -xf "bison-$VER.tar.xz"
			cd "bison-$VER"
			patch -Np1 -i "$PKGLUADIR/glr2.patch"
		fi
	]])
end

function build()
	-- bison 3.8.2's bundled gnulib predates glibc declaring
	-- posix_spawn_file_actions_addchdir (as a redirect to the _np symbol), so
	-- its link test fails and gnulib re-declares the function with a
	-- conflicting type. Tell configure what glibc actually provides.
	sh([[
		cd "bison-$VER"
		ac_cv_func_posix_spawn_file_actions_addchdir=yes \
		gl_cv_func_posix_spawn_works=yes \
		CFLAGS="${CFLAGS:-} -ffat-lto-objects" \
		./configure \
			--prefix=/usr \
			--datadir=/usr/share
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C "bison-$VER" DESTDIR="$ROOT" install
	]])
end

function test()
	cmd([[
		/usr/bin/bison --version || bison --version
	]])
end
