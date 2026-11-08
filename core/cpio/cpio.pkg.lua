local version = ZOI.VERSION or "2.15"

metadata({
	name = "cpio",
	repo = "core",
	version = version,
	revision = "1",
	description = "A tool to copy files into or out of a cpio or tar archive",
	website = "https://www.gnu.org/software/cpio",
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
	bins = { "cpio" },
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
					"pacman:gcc",
					"pacman:gettext",
					"pacman:git",
					"pacman:make",
					"pacman:rsync",
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
		if [ ! -d cpio ]; then
			git clone https://git.savannah.gnu.org/git/cpio.git cpio
			cd cpio
			git checkout -q "v$VER"
			# Pulls gnulib and paxutils
			git submodule update --init

			# Fix C23 conformity
			# https://cgit.git.savannah.gnu.org/cgit/cpio.git/commit/?id=f42137f5ab9cf07d1e62edc05e0212688d3ebaa2
			git cherry-pick -n f42137f5ab9cf07d1e62edc05e0212688d3ebaa2

			./bootstrap
		fi
	]])
end

function build()
	sh([[
		cd cpio
		./configure \
			--prefix=/usr \
			--mandir=/usr/share/man \
			--with-rmt=/dev/null
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C cpio DESTDIR="$ROOT" install
		find "$ROOT" -type d -empty -delete
	]])
end

function test()
	cmd([[
		/usr/bin/cpio --version || cpio --version
	]])
end
