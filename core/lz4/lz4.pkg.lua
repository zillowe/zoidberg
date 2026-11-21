local version = ZOI.VERSION or "1.11.1"
local sha512 = "1b9ecf6b5d0b53be6a7e28f85c63daeecfbf55dee2759dab5eb4647675975ccfe426152e382c30b8a8adb4038d40b312cceac4c56f348fb0977919869aa24669"
-- Upstream publishes the release tarball with a SHA-256 checksum but no
-- signature; the hash below was checked against it.

metadata({
	name = "lz4",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Extremely fast compression algorithm",
	website = "https://lz4.org",
	license = "BSD-2-Clause AND GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Yann Collet",
		website = "https://github.com/lz4/lz4",
	},
	bins = { "lz4", "lz4c", "lz4cat", "unlz4" },
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
					"pacman:curl",
					"pacman:gcc",
					"pacman:meson",
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
	local tarball = "lz4-" .. version .. ".tar.gz"
	sh([[
		fetch() {
			for base in \
				"https://github.com/lz4/lz4/releases/download/v$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "lz4-$VER.tar.gz"
		echo "$SHA512  lz4-$VER.tar.gz" | sha512sum -c -
	]])
	sh([[tar -xf "lz4-$VER.tar.gz"]])
end

function build()
	sh([[
		cd "lz4-$VER"
		meson setup _build build/meson \
			--prefix=/usr \
			--buildtype=plain \
			-Ddefault_library=shared \
			-Dprograms=true
		meson compile -C _build
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "lz4-$VER"
		meson install -C _build --destdir "$ROOT"
		for f in LICENSE lib/LICENSE programs/COPYING; do
			[ -f "$f" ] && install -Dm644 "$f" "$ROOT/usr/share/licenses/lz4/$(basename "$f")"
		done
		true
	]])
end
