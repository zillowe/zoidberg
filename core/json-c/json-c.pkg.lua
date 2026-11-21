local version = ZOI.VERSION or "0.19"
local sha512 = "e373559ab029deada3a3b350f626d8975ef6ebb7b40d50a8b4d0284323368b13f6976d3611f52e34d0a824134ea6d0519d56041140e5d1911c0fbc1b84167f37"
-- Upstream publishes the release tarball without a signature or checksum;
-- its contents were compared with the json-c-0.19-20260627 tag when this
-- hash was recorded.

metadata({
	name = "json-c",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "JSON implementation in C",
	website = "https://github.com/json-c/json-c",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "json-c contributors",
		website = "https://github.com/json-c/json-c",
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
					"pacman:base-devel",
					"pacman:cmake",
					"pacman:curl",
					"pacman:gcc",
					"pacman:ninja",
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
		.. "SHA512='" .. sha512 .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	local tarball = "json-c-" .. version .. ".tar.gz"
	sh([[
		fetch() {
			for base in \
				"https://s3.amazonaws.com/json-c_releases/releases"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "json-c-$VER.tar.gz"
		echo "$SHA512  json-c-$VER.tar.gz" | sha512sum -c -
	]])
	sh([[tar -xf "json-c-$VER.tar.gz"]])
end

function build()
	sh([[
		cd "json-c-$VER"
		cmake -S . -B _build -G Ninja \
			-DCMAKE_BUILD_TYPE=None \
			-DCMAKE_INSTALL_PREFIX=/usr \
			-DCMAKE_INSTALL_LIBDIR=lib \
			-DBUILD_STATIC_LIBS=OFF \
			-DENABLE_RDRAND=OFF \
			-DENABLE_THREADING=ON
		cmake --build _build
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "json-c-$VER"
		DESTDIR="$ROOT" cmake --install _build
		for f in COPYING; do
			[ -f "$f" ] && install -Dm644 "$f" "$ROOT/usr/share/licenses/json-c/$(basename "$f")"
		done
		true
	]])
end
