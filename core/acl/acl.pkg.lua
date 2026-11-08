local version = ZOI.VERSION or "2.4.0"

metadata({
	name = "acl",
	repo = "core",
	version = version,
	revision = "1",
	description = "Access control list utilities, libraries and headers",
	website = "https://savannah.nongnu.org/projects/acl",
	license = "LGPL-2.1-or-later AND GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The acl developers",
		website = "https://savannah.nongnu.org/projects/acl",
	},
	bins = { "chacl", "getfacl", "setfacl" },
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
					"pacman:attr",
					"pacman:autoconf",
					"pacman:automake",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:git",
					"pacman:libtool",
					"pacman:make",
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
		if [ ! -d acl ]; then
			git clone --depth 1 --branch "v$VER" https://git.savannah.nongnu.org/git/acl.git acl
			cd acl
			./autogen.sh
		fi
	]])
end

function build()
	sh([[
		cd acl
		./configure \
			--libdir=/usr/lib \
			--libexecdir=/usr/lib \
			--prefix=/usr
		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C acl DESTDIR="$ROOT" install
	]])
end

function test()
	cmd([[
		/usr/bin/getfacl --version || getfacl --version
	]])
end
