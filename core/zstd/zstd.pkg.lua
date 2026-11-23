local version = ZOI.VERSION or "1.5.7"
local sha512 = "b4de208f179b68d4c6454139ca60d66ed3ef3893a560d6159a056640f83d3ee67cdf6ffb88971cdba35449dba4b597eaa8b4ae908127ef7fd58c89f40bf9a705"
-- Release signing key (Zstandard Release Signing Key), from upstream's published keys.
local signing_key = "4EF4AC63455FC9F4545D9B7DEF8FE99528B52FFD"

metadata({
	name = "zstd",
	repo = "core",
	version = version,
	revision = "6",
	debug = { sub_package = true },
	description = "Zstandard - Fast real-time compression algorithm",
	website = "https://facebook.github.io/zstd/",
	license = "BSD-3-Clause AND GPL-2.0-only",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "Meta Platforms",
		website = "https://meta.com",
	},
	bins = { "zstd", "unzstd", "zstdcat", "zstdmt", "zstdgrep", "zstdless" },
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
					"pacman:curl",
					"pacman:gcc",
					"pacman:lz4",
					"pacman:ninja",
					"pacman:patch",
					"pacman:xz",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/gcc:libgcc",
			"zoi:@core/gcc:libstdc++",
			"zoi:@core/glibc",
			"zoi:@core/lz4",
			"zoi:@core/xz",
			"zoi:@core/zlib",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	local tarball = "zstd-" .. version .. ".tar.gz"
	cmd(
		[[
		fetch() {
			for base in \
				"https://github.com/facebook/zstd/releases/download/v$VER"; do
				curl -sSfL --retry 3 --retry-all-errors "$base/$1" -o "$1" && return 0
			done
			return 1
		}
		fetch "zstd-$VER.tar.gz"
		fetch "zstd-$VER.tar.gz.sig"
		echo "$SHA512  zstd-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	local key = LOCATION.PKGLUADIR .. "/keys/pgp/" .. signing_key .. ".asc"
	if not verifySignature(tarball, tarball .. ".sig", key) then
		error("bad upstream signature on " .. tarball)
	end
	cmd(
		[[
		tar -xf "zstd-$VER.tar.gz"
		cd "zstd-$VER"
		sed '/build static library to build tests/d' -i build/cmake/CMakeLists.txt
		sed 's/libzstd_static/libzstd_shared/g' -i build/cmake/tests/CMakeLists.txt

		# Upstream commit 6af3842118ea, regenerated man pages for 1.5.7.
		patch -Np1 -i "$PKGLUADIR/patches/0001-updated-man-pages-and-manual.patch"
	]],
		opts
	)
end

function build()
	cmd(
		[[
		cd "zstd-$VER"

		export CFLAGS="${CFLAGS} -ffat-lto-objects"
		export CXXFLAGS="${CXXFLAGS} -ffat-lto-objects"

		cmake -S build/cmake -B build -G Ninja \
			-DCMAKE_BUILD_TYPE=Release \
			-DCMAKE_INSTALL_PREFIX=/usr \
			-DCMAKE_INSTALL_LIBDIR=lib \
			-DZSTD_ZLIB_SUPPORT=ON \
			-DZSTD_LZMA_SUPPORT=ON \
			-DZSTD_LZ4_SUPPORT=ON \
			-DZSTD_BUILD_CONTRIB=ON \
			-DZSTD_BUILD_STATIC=OFF \
			-DZSTD_BUILD_TESTS=OFF \
			-DZSTD_PROGRAMS_LINK_SHARED=ON

		cmake --build build
	]],
		opts
	)
end

function package()
	cmd(
		[[
		mkdir -p "$ROOT"

		DESTDIR="$ROOT" cmake --install "zstd-$VER/build"
	]],
		opts
	)

	-- Dual-licensed: BSD-3-Clause (LICENSE) or GPL-2.0-only (COPYING).
	zlicense("zstd-" .. version .. "/LICENSE")
	zlicense("zstd-" .. version .. "/COPYING")
end

function test()
	cmd([[
		/usr/bin/zstd --version || zstd --version
	]])
end
