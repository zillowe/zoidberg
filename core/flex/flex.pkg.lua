local version = ZOI.VERSION or "2.6.4"

metadata({
	name = "flex",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "A tool for generating text-scanning programs",
	website = "https://github.com/westes/flex",
	license = "BSD-3-Clause-flex",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Flex Project",
		website = "https://github.com/westes/flex",
	},
	bins = { "flex", "flex++", "lex" },
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
					"pacman:curl",
					"pacman:gcc",
					"pacman:gettext",
					"pacman:help2man",
					"pacman:libtool",
					"pacman:m4",
					"pacman:make",
					"pacman:patch",
					"pacman:tar",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/bash",
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
		if [ ! -d "flex-$VER" ]; then
			curl -sSfL "https://github.com/westes/flex/releases/download/v$VER/flex-$VER.tar.gz" -o "flex-$VER.tar.gz"
			echo "e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995  flex-$VER.tar.gz" | sha256sum -c -
			tar -xf "flex-$VER.tar.gz"
			cd "flex-$VER"
			patch -p1 -i "$PKGLUADIR/flex-pie.patch"
			autoreconf -fiv
		fi
	]])
end

function build()
	sh([[
		cd "flex-$VER"
		./configure --prefix=/usr
		# Prevent excessive overlinking due to libtool
		sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make -C "flex-$VER" DESTDIR="$ROOT" install
		ln -sf flex "$ROOT/usr/bin/lex"

		install -Dm644 "flex-$VER/COPYING" "$ROOT/usr/share/licenses/flex/license.txt"
	]])
end

function test()
	cmd([[
		/usr/bin/flex --version || flex --version
	]])
end
