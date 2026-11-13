local version = ZOI.VERSION or "5.4"

metadata({
	name = "debugedit",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Tool to mangle source locations in .debug files",
	website = "https://sourceware.org/debugedit/",
	license = "GPL-3.0-or-later AND GPL-2.0-or-later AND LGPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The debugedit developers",
		website = "https://sourceware.org/debugedit/",
	},
	bins = { "debugedit", "find-debuginfo", "sepdebugcrcfix" },
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
					"pacman:elfutils",
					"pacman:gcc",
					"pacman:help2man",
					"pacman:libtool",
					"pacman:make",
					"pacman:patch",
					"pacman:tar",
					"pacman:xxhash",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		-- gdb is optional: find-debuginfo only uses it for gdb-add-index.
		required = {
			"zoi:@core/bash",
			"zoi:@core/cpio",
			"zoi:@core/elfutils",
			"zoi:@core/elfutils:libelf",
			"zoi:@core/glibc",
			"zoi:@core/xxhash",
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
		if [ ! -d "debugedit-$VER" ]; then
			curl -sSfL "https://sourceware.org/ftp/debugedit/$VER/debugedit-$VER.tar.xz" -o "debugedit-$VER.tar.xz"
			echo "a5813796779f7a09c4845b4d995296692d88ab8fe889c7c97b1f868dec4b6f9c426bcb18dd051a6f49e2275d553374103460c1b700e78c4db7dc7eafd4c55342  debugedit-$VER.tar.xz" | sha512sum -c -
			tar -xf "debugedit-$VER.tar.xz"
			cd "debugedit-$VER"
			patch -Np1 < "$PKGLUADIR/remove-dwz.patch"
			autoreconf -fiv
		fi
	]])
end

function build()
	sh([[
		cd "debugedit-$VER"
		./configure --prefix=/usr
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C "debugedit-$VER" DESTDIR="$ROOT" install
	]])
end

function test()
	cmd([[
		/usr/bin/debugedit --version || debugedit --version
	]])
end
