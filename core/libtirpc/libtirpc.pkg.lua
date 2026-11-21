local version = ZOI.VERSION or "1.3.8"
local sha512 = "390c06b8beeb2b0110ab68953d23fef10c823f598146c7fcebce0cb461d6112d0163eded09fd0b5d3e82d0e189a48184ab3d09b994a41f5cbe4799c16eb1a117"
-- Upstream publishes release tarballs without signatures; the hash below
-- matches the one Arch Linux pins for the same tarball.

metadata({
	name = "libtirpc",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Transport-independent RPC library",
	website = "https://sourceforge.net/projects/libtirpc/",
	license = "BSD-3-Clause",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "libtirpc contributors",
		website = "https://sourceforge.net/projects/libtirpc/",
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
					"pacman:curl",
					"pacman:gcc",
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
		.. "SHA512='" .. sha512 .. "'\n"
		.. "ROOT='" .. root .. "'\n"
	local _, stderr, code = cmd("(\nset -e\n" .. env .. script .. "\n)")
	if code ~= 0 then
		error("command failed with exit code " .. tostring(code) .. "\n" .. (stderr or ""))
	end
end

function prepare()
	local tarball = "libtirpc-" .. version .. ".tar.bz2"
	sh([[
		fetch() {
			for base in \
				"https://downloads.sourceforge.net/sourceforge/libtirpc"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libtirpc-$VER.tar.bz2"
		echo "$SHA512  libtirpc-$VER.tar.bz2" | sha512sum -c -
	]])
	sh([[tar -xf "libtirpc-$VER.tar.bz2"]])
end

function build()
	sh([[
		cd "libtirpc-$VER"
		./configure --prefix=/usr --sysconfdir=/etc --disable-static --disable-gssapi
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "libtirpc-$VER"
		make DESTDIR="$ROOT" install
		for f in COPYING; do
			[ -f "$f" ] && install -Dm644 "$f" "$ROOT/usr/share/licenses/libtirpc/$(basename "$f")"
		done
		true
	]])
end
