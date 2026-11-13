local version = ZOI.VERSION or "1.5.7"
local tag = "v" .. version
local git_url = "https://github.com/facebook/zstd.git"

metadata({
	name = "zstd",
	repo = "core",
	version = version,
	revision = "3",
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
					"pacman:git",
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
			"zoi:@core/xz",
			"zoi:@core/zlib",
		},
	},
})

function prepare()
	cmd(string.format(
		[[
		if [ ! -d zstd ]; then
			git clone --depth 1 --branch %s %s zstd
		fi

		cd zstd
		sed '/build static library to build tests/d' -i build/cmake/CMakeLists.txt 2>/dev/null || true
		sed 's/libzstd_static/libzstd_shared/g' -i build/cmake/tests/CMakeLists.txt 2>/dev/null || true

		if [ ! -f .patched ]; then
			curl -sSL "https://github.com/facebook/zstd/commit/6af3842118ea5325480b403213b2a9fbed3d3d74.patch" | patch -Np1 || true
			touch .patched
		fi
	]],
		tag,
		git_url
	))
end

function build()
	cmd([[
		set -e
		cd zstd

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
	]])
end

function package()
	local root = LOCATION.ROOT or (STAGING_DIR .. "/usrroot")

	cmd(string.format(
		[[
		set -e
		ROOT="%s"
		mkdir -p "$ROOT"

		DESTDIR="$ROOT" cmake --install zstd/build
	]],
		root
	))

	-- zlicense("LICENSE")
end

function test()
	cmd([[
		/usr/bin/zstd --version || zstd --version
	]])
end
