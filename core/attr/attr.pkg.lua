local version = ZOI.VERSION or "2.6.0"

metadata({
	name = "attr",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "Extended attribute support library for ACL support",
	website = "https://savannah.nongnu.org/projects/attr",
	license = "LGPL-2.1-or-later AND GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The attr developers",
		website = "https://savannah.nongnu.org/projects/attr",
	},
	bins = { "attr", "getfattr", "setfattr" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	backup = {
		"${usrroot}/etc/xattr.conf",
	},
})

dependencies({
	build = {
		types = {
			source = {
				required = {
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
		if [ ! -d attr ]; then
			git clone --depth 1 --branch "v$VER" https://git.savannah.nongnu.org/git/attr.git attr
			cd attr

			# Remove the nfs entries from /etc/xattr.conf
			# http://lists.gnu.org/archive/html/bug-coreutils/2019-03/msg00008.html
			sed -i '/nfs/d' xattr.conf

			./autogen.sh
		fi
	]])
end

function build()
	sh([[
		cd attr
		./configure \
			--libdir=/usr/lib \
			--libexecdir=/usr/lib \
			--prefix=/usr \
			--sysconfdir=/etc
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C attr DESTDIR="$ROOT" install
	]])
end

function test()
	cmd([[
		/usr/bin/getfattr --version || getfattr --version
	]])
end
