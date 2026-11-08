local version = ZOI.VERSION or "2.73"

metadata({
	name = "autoconf",
	repo = "core",
	version = version,
	revision = "1",
	description = "A GNU tool for automatically configuring source code",
	website = "https://www.gnu.org/software/autoconf",
	license = "GPL-2.0-or-later AND GPL-3.0-or-later WITH Autoconf-exception-3.0",
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
		"autoconf",
		"autoheader",
		"autom4te",
		"autoreconf",
		"autoscan",
		"autoupdate",
		"ifnames",
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
					"pacman:m4",
					"pacman:make",
					"pacman:perl",
					"pacman:tar",
					"pacman:xz",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
			"zoi:@core/diffutils",
			"zoi:@core/gawk",
			"zoi:@core/m4",
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
		if [ ! -d "autoconf-$VER" ]; then
			curl -sSfL "https://ftp.gnu.org/pub/gnu/autoconf/autoconf-$VER.tar.xz" -o "autoconf-$VER.tar.xz"
			echo "9fd672b1c8425fac2fa67fa0477b990987268b90ff36d5f016dae57be0d6b52e  autoconf-$VER.tar.xz" | sha256sum -c -
			tar -xf "autoconf-$VER.tar.xz"
		fi
	]])
end

function build()
	sh([[
		cd "autoconf-$VER"
		./configure --prefix=/usr
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C "autoconf-$VER" DESTDIR="$ROOT" install

		# License exception
		install -Dm644 "autoconf-$VER/COPYING.EXCEPTION" "$ROOT/usr/share/licenses/autoconf/COPYING.EXCEPTION"

		# Don't ship the GNU coding standards manual
		rm -f "$ROOT/usr/share/info/standards.info"
	]])
end

function test()
	cmd([[
		/usr/bin/autoconf --version || autoconf --version
	]])
end
