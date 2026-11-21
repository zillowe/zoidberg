local version = ZOI.VERSION or "1.2.1"
local sha512 = "460591287d428c8b5a8a2766b5b424d14501fcda12c7118b8f3cc4bfae44b90ac75ca156557f07b6e22542612724d904533e5f70019be07dbbb604c46f03ab69"
-- Upstream publishes no release tarball or signature; this is GitHub's
-- archive of the v1.2.1 tag, pinned by hash.

metadata({
	name = "brotli",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Generic-purpose lossless compression algorithm",
	website = "https://github.com/google/brotli",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Google",
		website = "https://github.com/google/brotli",
	},
	bins = { "brotli" },
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
					"pacman:make",
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
	local tarball = "brotli-" .. version .. ".tar.gz"
	sh([[
		curl -sSfL --retry 3 --retry-all-errors "https://github.com/google/brotli/archive/refs/tags/v$VER.tar.gz" -o "brotli-$VER.tar.gz"
		echo "$SHA512  brotli-$VER.tar.gz" | sha512sum -c -
	]])
	sh([[tar -xf "brotli-$VER.tar.gz"]])
end

function build()
	sh([[
		cd "brotli-$VER"
		cmake -S . -B _build -G Ninja \
			-DCMAKE_BUILD_TYPE=Release \
			-DCMAKE_INSTALL_PREFIX=/usr \
			-DCMAKE_INSTALL_LIBDIR=lib \
			-DBUILD_SHARED_LIBS=ON
		cmake --build _build
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "brotli-$VER"
		DESTDIR="$ROOT" cmake --install _build
		for f in LICENSE; do
			[ -f "$f" ] && install -Dm644 "$f" "$ROOT/usr/share/licenses/brotli/$(basename "$f")"
		done
		true
	]])
end
