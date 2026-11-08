local version = ZOI.VERSION or "0.8.4"

metadata({
	name = "xxhash",
	repo = "core",
	version = version,
	revision = "1",
	description = "Extremely fast non-cryptographic hash algorithm",
	website = "https://cyan4973.github.io/xxHash/",
	license = "BSD-2-Clause AND GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Yann Collet",
		website = "https://github.com/Cyan4973/xxHash",
	},
	bins = { "xxhsum", "xxh32sum", "xxh64sum", "xxh128sum", "xxh3sum" },
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
					"pacman:gcc",
					"pacman:git",
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
		if [ ! -d xxHash ]; then
			git clone --depth 1 --branch "v$VER" https://github.com/Cyan4973/xxHash.git xxHash
		fi
	]])
end

function build()
	sh([[
		make -j"$(nproc)" PREFIX=/usr DISPATCH=1 -C xxHash
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		make PREFIX=/usr DISPATCH=1 DESTDIR="$ROOT" -C xxHash install
		install -Dm644 xxHash/LICENSE -t "$ROOT/usr/share/licenses/xxhash"
	]])
end

function test()
	cmd([[
		/usr/bin/xxhsum --version || xxhsum --version
	]])
end
