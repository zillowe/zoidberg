local version = ZOI.VERSION or "3.8.1"
local sha512 = "44370f8779765ac83161d927025c8178919ae30feffaad6cdd2b9f95fd8314ca96d2c75d23d102f4af06e55787ec25ebf3cf35cec6ea6881c16e526b27bec0dc"
-- Upstream publishes release tarballs without signatures; the hash below
-- matches the SHA-256 GitHub records for the release asset.

metadata({
	name = "libffi",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Portable foreign function interface library",
	website = "https://sourceware.org/libffi/",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Anthony Green",
		website = "https://sourceware.org/libffi/",
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
	local tarball = "libffi-" .. version .. ".tar.gz"
	sh([[
		fetch() {
			for base in \
				"https://github.com/libffi/libffi/releases/download/v$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libffi-$VER.tar.gz"
		echo "$SHA512  libffi-$VER.tar.gz" | sha512sum -c -
	]])
	sh([[tar -xf "libffi-$VER.tar.gz"]])
end

function build()
	sh([[
		cd "libffi-$VER"
		./configure \
			--prefix=/usr \
			--disable-static \
			--disable-multi-os-directory \
			--disable-exec-static-tramp \
			--enable-pax_emutramp
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "libffi-$VER"
		make DESTDIR="$ROOT" install
		for f in LICENSE; do
			[ -f "$f" ] && install -Dm644 "$f" "$ROOT/usr/share/licenses/libffi/$(basename "$f")"
		done
		true
	]])
end
