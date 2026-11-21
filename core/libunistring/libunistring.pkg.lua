local version = ZOI.VERSION or "1.5"
local sha512 = "cbf6a1ddb8dbdd922d7650c110adef285133c303e69e943fbe240bc988954912f0fc7fbd205feacb3f6b98bda53df07ee2ad4e9ec241b8e78d0c52083a9f5c32"
-- Release signing key (Bruno Haible), from upstream's published keys.
local signing_key = "E0FFBD975397F77A32AB76ECB6301D9E1BBEAC08"

metadata({
	name = "libunistring",
	repo = "core",
	version = version,
	revision = "1",
	debug = { sub_package = true },
	description = "Library for manipulating Unicode strings and C strings",
	website = "https://www.gnu.org/software/libunistring/",
	license = "LGPL-3.0-or-later OR GPL-2.0-or-later",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Free Software Foundation",
		website = "https://www.fsf.org",
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
	local tarball = "libunistring-" .. version .. ".tar.xz"
	sh([[
		fetch() {
			for base in \
				"https://ftpmirror.gnu.org/gnu/libunistring" \
				"https://mirrors.kernel.org/gnu/libunistring" \
				"https://ftp.gnu.org/gnu/libunistring"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "libunistring-$VER.tar.xz"
		fetch "libunistring-$VER.tar.xz.sig"
		echo "$SHA512  libunistring-$VER.tar.xz" | sha512sum -c -
	]])
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	sh([[tar -xf "libunistring-$VER.tar.xz"]])
end

function build()
	sh([[
		cd "libunistring-$VER"
		./configure --prefix=/usr --disable-static
		make -j"$(nproc)"
	]])
end

function package()
	sh([[
		mkdir -p "$ROOT"
		cd "libunistring-$VER"
		make DESTDIR="$ROOT" install
		for f in COPYING COPYING.LIB; do
			[ -f "$f" ] && install -Dm644 "$f" "$ROOT/usr/share/licenses/libunistring/$(basename "$f")"
		done
		true
	]])
end
