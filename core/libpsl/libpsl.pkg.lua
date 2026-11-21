local version = ZOI.VERSION or "0.21.5"
local sha512 = "c14d575cecc0f1693894dd79565b6b9220084ddfa43b908a1cefe16d147cdd5ec47796eb0c2135e2f829a951abaf39d8a371ab5c1352f57b36e610e25adf91f5"
-- Release signing key (Tim Rühsen), from upstream's published keys.
local signing_key = "1CB27DBC98614B2D5841646D08302DB6A2670428"

metadata({
	name = "libpsl",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Public Suffix List library",
	website = "https://github.com/rockdaboot/libpsl",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Tim Rühsen",
		website = "https://github.com/rockdaboot",
	},
	bins = { "psl" },
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
					"pacman:libidn2",
					"pacman:libunistring",
					"pacman:make",
					"pacman:python",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
			"zoi:@core/libidn2",
			"zoi:@core/libunistring",
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
	local tarball = "libpsl-" .. version .. ".tar.gz"
	sh([[
		fetch() {
			for base in \
				"https://github.com/rockdaboot/libpsl/releases/download/$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libpsl-$VER.tar.gz"
		fetch "libpsl-$VER.tar.gz.sig"
		echo "$SHA512  libpsl-$VER.tar.gz" | sha512sum -c -
	]])
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	sh([[tar -xf "libpsl-$VER.tar.gz"]])
end

function build()
	sh([[
		cd "libpsl-$VER"
		./configure \
			--prefix=/usr \
			--disable-static \
			--disable-gtk-doc \
			--enable-builtin \
			--enable-runtime=libidn2
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "libpsl-$VER"
		make DESTDIR="$ROOT" install
		for f in COPYING; do
			[ -f "$f" ] && install -Dm644 "$f" "$ROOT/usr/share/licenses/libpsl/$(basename "$f")"
		done
		true
	]])
end
