local version = ZOI.VERSION or "1.5.8"
local sha512 = "0ae94df4bd508f0e664fa5430687d64904c60d69d9565c18cacb70251f8653cb7c571325d1406c859fdd149048adce8c4b3bf028573064496d7da3436e27b9b0"
-- Release signing key (Colin Watson), from upstream's published keys.
local signing_key = "AC0A4FF12611B6FCCF01C111393587D97D86500B"

metadata({
	name = "libpipeline",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "A C library for manipulating pipelines of subprocesses",
	website = "https://libpipeline.nongnu.org/",
	license = "GPL-3.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Colin Watson",
		website = "https://libpipeline.nongnu.org/",
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
	local tarball = "libpipeline-" .. version .. ".tar.gz"
	sh([[
		fetch() {
			for base in \
				"https://download.savannah.nongnu.org/releases/libpipeline" \
				"https://download-mirror.savannah.gnu.org/releases/libpipeline"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libpipeline-$VER.tar.gz"
		fetch "libpipeline-$VER.tar.gz.asc"
		echo "$SHA512  libpipeline-$VER.tar.gz" | sha512sum -c -
	]])
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".asc", key) then
		error("bad upstream signature on " .. tarball)
	end
	sh([[tar -xf "libpipeline-$VER.tar.gz"]])
end

function build()
	sh([[
		cd "libpipeline-$VER"
		./configure --prefix=/usr --disable-static
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "libpipeline-$VER"
		make DESTDIR="$ROOT" install
		for f in COPYING; do
			[ -f "$f" ] && install -Dm644 "$f" "$ROOT/usr/share/licenses/libpipeline/$(basename "$f")"
		done
		true
	]])
end
