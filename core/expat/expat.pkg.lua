local version = ZOI.VERSION or "2.10.0"
local tag = "R_" .. string.gsub(version, "%.", "_")

metadata({
	name = "expat",
	repo = "core",
	version = version,
	revision = "2",
	debug = { sub_package = true },
	description = "An XML parser library",
	website = "https://libexpat.github.io/",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "The Expat developers",
		website = "https://libexpat.github.io/",
	},
	bins = { "xmlwf" },
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
					"pacman:cmake",
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
		.. "TAG='" .. tag .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	sh([[
		if [ ! -d expat ]; then
			git clone --depth 1 --branch "$TAG" https://github.com/libexpat/libexpat.git expat
		fi
	]])
end

function build()
	sh([[
		cmake \
			-B build \
			-D CMAKE_BUILD_TYPE=None \
			-D CMAKE_INSTALL_PREFIX=/usr \
			-S expat/expat \
			-W no-dev
		cmake --build build --verbose -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		DESTDIR="$ROOT" cmake --install build
		install -vDm644 expat/expat/COPYING -t "$ROOT/usr/share/licenses/expat/"
		install -vDm644 expat/expat/AUTHORS expat/expat/Changes expat/expat/README.md -t "$ROOT/usr/share/doc/expat/"
	]])
end

function test()
	cmd([[
		/usr/bin/xmlwf -v || xmlwf -v
	]])
end
