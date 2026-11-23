local version = ZOI.VERSION or "2.71.0"
local sha512 = "d13b865c3b16a515c89359fb5ea03c17e50ee7b0860470d24265e4b85cbe537754749e388b795c0b36328c024e785fb9397a62c85b1c98e7cde26c35768aa3b7"
-- Upstream publishes no source tarball or signature; this is GitHub's
-- archive of the 2.71.0 tag, pinned by hash. The hash matches Gentoo's
-- Manifest (sha512) and Arch Linux's PKGBUILD (sha256).

metadata({
	name = "fastfetch",
	repo = "extra",
	version = version,
	revision = "1",
	description = "A feature-rich and performance oriented neofetch like system information tool",
	website = "https://github.com/fastfetch-cli/fastfetch",
	git = "https://github.com/fastfetch-cli/fastfetch",
	license = "MIT",
	maintainer = {
		name = "Zillowe Foundation",
		website = "https://zillowe.qzz.io",
		email = "contact@zillowe.qzz.io",
	},
	author = {
		name = "fastfetch contributors",
		website = "https://github.com/fastfetch-cli/fastfetch",
	},
	bins = { "fastfetch" },
	scope = "system",
	scopes = { "system" },
	platforms = { "linux-amd64" },
	types = { "source" },
	zoios = true,
	tags = { "c", "cli", "system-info", "fetch" },
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
					"pacman:pkgconf",
					-- Generates the full man page and minifies help.json.
					"pacman:python",
					-- Headers for features fastfetch loads with dlopen() at
					-- runtime; none of these becomes a hard dependency.
					"pacman:chafa",
					"pacman:dbus",
					"pacman:dconf",
					"pacman:imagemagick",
					"pacman:libdrm",
					"pacman:libelf",
					"pacman:libglvnd",
					"pacman:libva",
					"pacman:libvdpau",
					"pacman:libxcb",
					"pacman:libxrandr",
					"pacman:lua",
					"pacman:ocl-icd",
					"pacman:opencl-headers",
					"pacman:sqlite",
					"pacman:vulkan-headers",
					"pacman:vulkan-icd-loader",
					"pacman:wayland",
					"pacman:xfconf",
					"pacman:zlib",
				},
			},
		},
	},
	runtime = {
		required = {
			"zoi:@core/glibc",
		},
		optional = {
			"zoi:@core/hwdata: GPU names (pci.ids)",
			"zoi:@core/zlib: faster image output with the kitty graphics protocol",
			"zoi:@core/sqlite: SQLite integration and Soar package count",
		},
	},
})

-- Every shell step runs checked (`set -e`, a failure stops the build) with
-- these variables. `$ROOT` (the staged system root) is always set by cmd().
local opts = { check = true, env = { VER = version, SHA512 = sha512 } }

function prepare()
	cmd(
		[[
		curl -sSfL --retry 3 --retry-all-errors \
			"https://github.com/fastfetch-cli/fastfetch/archive/refs/tags/$VER.tar.gz" \
			-o "fastfetch-$VER.tar.gz"
		echo "$SHA512  fastfetch-$VER.tar.gz" | sha512sum -c -
	]],
		opts
	)
	cmd([[tar -xf "fastfetch-$VER.tar.gz"]], opts)
end

function build()
	-- Options follow Arch Linux's PKGBUILD, except that yyjson is the copy
	-- bundled with fastfetch (no system yyjson in Zoidberg) and flashfetch
	-- (a hardcoded-config demo binary) is not built, as Arch and Gentoo do.
	cmd(
		[[
		cd "fastfetch-$VER"
		cmake -S . -B _build -G Ninja \
			-DCMAKE_BUILD_TYPE=Release \
			-DCMAKE_INSTALL_PREFIX=/usr \
			-DBUILD_FLASHFETCH=OFF \
			-DBUILD_TESTS=OFF \
			-DENABLE_SYSTEM_YYJSON=OFF \
			-DENABLE_SQLITE3=ON \
			-DENABLE_RPM=OFF \
			-DENABLE_IMAGEMAGICK6=OFF \
			-DPACKAGES_DISABLE_APK=ON \
			-DPACKAGES_DISABLE_DPKG=ON \
			-DPACKAGES_DISABLE_EMERGE=ON \
			-DPACKAGES_DISABLE_EOPKG=ON \
			-DPACKAGES_DISABLE_GUIX=ON \
			-DPACKAGES_DISABLE_LINGLONG=ON \
			-DPACKAGES_DISABLE_LPKG=ON \
			-DPACKAGES_DISABLE_LPKGBUILD=ON \
			-DPACKAGES_DISABLE_OPKG=ON \
			-DPACKAGES_DISABLE_PACSTALL=ON \
			-DPACKAGES_DISABLE_PALUDIS=ON \
			-DPACKAGES_DISABLE_PKG=ON \
			-DPACKAGES_DISABLE_PKGTOOL=ON \
			-DPACKAGES_DISABLE_RPM=ON \
			-DPACKAGES_DISABLE_SORCERY=ON \
			-DPACKAGES_DISABLE_XBPS=ON \
			-Wno-dev
		cmake --build _build
	]],
		opts
	)
end

function package()
	-- Installs shell completions, presets and the man page. The license it
	-- also installs is removed and staged with zlicense() instead.
	cmd(
		[[
		cd "fastfetch-$VER"
		DESTDIR="$ROOT" cmake --install _build
		rm -rf "$ROOT/usr/share/licenses"
	]],
		opts
	)

	zlicense("fastfetch-" .. version .. "/LICENSE")
end

function test()
	cmd([["$ROOT/usr/bin/fastfetch" --version]], opts)
	return true
end
